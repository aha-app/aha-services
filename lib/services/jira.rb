require 'html2confluence'

class AhaServices::Jira < AhaService
  title "JIRA"
  
  string :server_url, description: "URL for the JIRA server, without the trailing slash, e.g. https://bigaha.atlassian.net"
  string :username, description: "Use your JIRA username from the JIRA profile page, not your email address."
  password :password
  install_button
  select :project, collection: ->(meta_data, data) { meta_data.projects.collect{|p| [p.name, p['key']] } }
  boolean :send_initiatives, description: "Check to use feature initatives to create Epics in JIRA Agile"
  select :feature_issue_type, 
    collection: ->(meta_data, data) { 
      meta_data.projects.detect {|p| p['key'] == data.project}.issue_types.find_all{|i| !i['subtype']}.collect{|p| [p.name, p.id] } 
    }, description: "JIRA issue type that will be used when sending features. If you are using JIRA Agile then we recommend 'Story'."
  select :requirement_issue_type, 
    collection: ->(meta_data, data) { 
      meta_data.projects.detect {|p| p['key'] == data.project}.issue_types.find_all{|i| !i['subtype']}.collect{|p| [p.name, p.id] } 
    }, description: "JIRA issue type that will be used when sending requirements. If you are using JIRA Agile then we recommend 'Sub-task'."
  internal :feature_status_mapping
  internal :resolution_mapping
  boolean :send_tags, description: "Check to synchronize Aha! tags and JIRA labels. We recommend enabling this for new integrations. Enabling this option once features are synced to JIRA may cause tags in Aha! or labels in JIRA to be removed from a feature if the corresponding label or tag doesn't exist in the other system."
  
  callback_url description: "URL to add to the webhooks section of JIRA. Only one hook is necessary, even if multiple products are integrated with JIRA."
  
  def receive_installed
    @meta_data.projects = project_resource.all
    
    @meta_data.resolutions = resolution_resource.all

    # Get custom field mappings.
    @meta_data.epic_name_field = field_resource.epic_name_field
    @meta_data.epic_link_field = field_resource.epic_link_field
    @meta_data.story_points_field = field_resource.story_points_field
    @meta_data.aha_reference_field = field_resource.aha_reference_field
    
    # Create custom field for Aha! reference.
    unless @meta_data.aha_reference_field
      field = {
        name: "Aha! Reference",
        description: "Link to the Aha! item this issue is related to.",
        type: "com.atlassian.jira.plugin.system.customfieldtypes:url"
      }

      @meta_data.aha_reference_field = field_resource.create(field)
      
      # Add field to the default screen.
      field_resource.add_to_default_screen(@meta_data.aha_reference_field)
    end
  end
  
  def receive_create_feature
    version = find_or_attach_jira_version(payload.feature.release)
    issue_info = update_or_attach_jira_issue(payload.feature, payload.feature.initiative, version)
    update_requirements(payload.feature, version, issue_info)
  end
  
  def receive_update_feature
    version = find_or_attach_jira_version(payload.feature.release)
    issue_info = update_or_attach_jira_issue(payload.feature, payload.feature.initiative, version)
    update_requirements(payload.feature, version, issue_info)
  end

  def receive_create_release
    find_or_attach_jira_version(payload.release)
  end
  
  def receive_update_release
    update_or_attach_jira_version(payload.release)
  end

  # These methods are exposed here so they can be used in the callback and
  # import code.
  def get_issue(issue_id)
    issue_resource.find_by_id(issue_id, expand: "renderedFields")
  end

  def search_issues(params)
    issue_resource.search(params)
  end

protected

  def find_or_attach_jira_version(release)
    if version = existing_version_integrated_with(release)
      version
    else
      attach_version_to(release)
    end
  end
  
  def update_or_attach_jira_version(release)
    if version_id = get_integration_field(release.integration_fields, 'id')
      update_version(version_id, release)
    else
      attach_version_to(release)
    end
  end

  def existing_version_integrated_with(release)
    if version_id = get_integration_field(release.integration_fields, 'id')
      version_resource.find_by_id(version_id)
    end
  end

  def attach_version_to(release)
    unless version = version_resource.find_by_name(release.name)
      version = create_version_for(release)
    end
    integrate_release_with_jira_version(release, version)
    version
  end

  def create_version_for(release)
    version_resource.create name: release.name,
                            description: "Created from Aha! #{release.url}",
                            releaseDate: release.release_date,
                            released: release.released
  end

  def update_version(id, release)
    version_resource.update id, name: release.name,
                                releaseDate: release.release_date,
                                released: release.released
  end
  
  def update_requirements(feature, version, issue_info)
    if feature.requirements
      feature.requirements.each do |requirement|
        update_or_attach_jira_issue(requirement, feature.initiative, version, issue_info)
      end
    end
  end

  def get_existing_issue_info(resource)
    if id = get_integration_field(resource.integration_fields, 'id') and
      key = get_integration_field(resource.integration_fields, 'key')
      { 'id' => id, 'key' => key }
    else
      nil
    end
  end
  
  def update_or_attach_jira_issue(resource, initiative, version, parent = nil)
    if issue_info = get_existing_issue_info(resource)
      update_issue(issue_info, resource, initiative, version, parent)
    else
      attach_issue_to(resource, initiative, version, parent)
    end
  end

  def attach_issue_to(resource, initiative, version, parent = nil)
    issue_info = create_issue_for(resource, initiative, version, parent)
    integrate_resource_with_jira_issue(reference_num_to_resource_type(resource.reference_num), resource, issue_info)

    # Add attachments.
    resource.description.attachments.each do |attachment|
      attachment_resource.upload(attachment, issue_info['id'])
    end
    resource.attachments.each do |attachment|
      attachment_resource.upload(attachment, issue_info['id'])
    end

    issue_info
  end
  
  # Create an epic from an initiative, or find an existing epic for the 
  # initiative.
  def find_or_create_epic_from_initiative(initiative)
    if epic_key = get_integration_field(initiative.integration_fields, 'key')
      epic_key
    else
      issue = {
        fields: {
          :summary => initiative.name,
          :description => convert_html(initiative.description.body),
          :issuetype => {name: "Epic"}
        }
      }
      if @meta_data.aha_reference_field
        issue[:fields][@meta_data.aha_reference_field] = initiative.url
      end
      issue[:fields][@meta_data.epic_name_field] = initiative.name
      
      new_issue = issue_resource.create(issue)
      initiative.description.attachments.each do |attachment|
        attachment_resource.upload(attachment, new_issue['id'])
      end
      begin
        integrate_resource_with_jira_issue("initiatives", initiative, new_issue)
      rescue AhaApi::BadRequest
        # Failure was probably due to initiative from another product, convert
        # to a more user friendly message.
        raise AhaService::RemoteError, "Initiative '#{initiative.name}' is from a product without a JIRA integration. Add a JIRA integration for the product the initiative belongs to."
      end
      new_issue['key']
    end
  end
  
  def create_issue_for(resource, initiative, version, parent)
    issue_type_id = parent ? (data.requirement_issue_type || data.feature_issue_type) : data.feature_issue_type
    issue_type = issue_type(issue_type_id)
    summary = resource.name || description_to_title(resource.description.body)

    issue = {
      fields: {
        summary: summary,
        description: convert_html(resource.description.body),
        issuetype: {id: issue_type_id}
      }
    }
    if version
      issue[:fields][:fixVersions] = [{id: version['id']}]
    end
    if data.send_tags == "1" and resource.tags
      issue[:fields][:labels] = resource.tags
    end
      
    if @meta_data.aha_reference_field
      issue[:fields][@meta_data.aha_reference_field] = resource.url
    end
    populate_relationship_fields(issue, parent, initiative)
    populate_time_tracking(issue, resource, parent)
    
    new_issue = issue_resource.create(issue)

    # Create links.
    if parent and !issue_type['subtask'] and !["Epic", "Story"].include?(issue_type['name'])
      link = {
        type: {
          name: "Relates"
        },
        outwardIssue: {
          id: new_issue['id']
        },
        inwardIssue: {
          id: parent['id']
        }
      }
      issue_link_resource.create(link)
    end

    new_issue
  end

  def update_issue(issue_info, resource, initiative, version, parent)
    issue = {
      fields: {
        description: convert_html(resource.description.body),
      }
    }
    issue[:fields][:summary] = resource.name if resource.name
    if version['id']
      issue[:update] ||= {}
      issue[:update][:fixVersions] = [{set: [{id: version['id']}]}]
    end
    if data.send_tags == "1" and resource.tags
      issue[:fields][:labels] = resource.tags
    end
    
    # Disabled until https://jira.atlassian.com/browse/GHS-10333 is fixed.
    #populate_relationship_fields(issue, parent, initiative)
    populate_time_tracking(issue, resource, parent)

    issue_resource.update(issue_info['id'], issue)

    update_attachments(issue_info['id'], resource)
    
    issue_info
  end

  def project_resource
    @project_resource ||= JiraProjectResource.new(self)
  end

  def resolution_resource
    @resolution_resource ||= JiraResolutionResource.new(self)
  end

  def field_resource
    @field_resource ||= JiraFieldResource.new(self)
  end

  def version_resource
    @version_resource ||= JiraVersionResource.new(self)
  end

  def issue_resource
    @issue_resource ||= JiraIssueResource.new(self)
  end

  def issue_link_resource
    @issue_link_resource ||= JiraIssueLinkResource.new(self)
  end

  def attachment_resource
    @attachment_resource ||= JiraAttachmentResource.new(self)
  end
  
  def update_attachments(issue_id, resource)
    # New list of attachments.
    attachments = resource.attachments.dup | resource.description.attachments.dup
    
    # Get the current attachments.
    attachment_resource.all_for_issue(issue_id).each do |attachment|
      # Remove any attachments that match.
      attachments.reject! do |a|
        a.file_name == attachment["filename"] and a.file_size.to_i == attachment["size"].to_i
      end
    end
    
    # Create any attachments that didn't already exist.
    attachments.each do |attachment|
      attachment_resource.upload(attachment, issue_id)
    end
  end
  
  def populate_time_tracking(issue, resource, parent)
    issue_type_id = parent ? (data.requirement_issue_type || data.feature_issue_type) : data.feature_issue_type
    issue_type = issue_type(issue_type_id)

    if resource.work_units == 10 # Units are minutes.
      issue[:fields][:timetracking] = {
        originalEstimate: resource.original_estimate,
        remainingEstimate: resource.remaining_estimate
      }
    elsif resource.work_units == 20 and @meta_data.story_points_field # Units are points.
      logger.debug("ISSUE TYPE: #{issue_type.inspect} #{issue_type['name']}")
      # We can only do this if the issue is a story.
      if issue_type['name'] == "Story"
        issue[:fields][@meta_data.story_points_field] = resource.remaining_estimate
      end
    end
  end
  
  def populate_relationship_fields(issue, parent, initiative)
    issue_type_id = parent ? (data.requirement_issue_type || data.feature_issue_type) : data.feature_issue_type
    issue_type = issue_type(issue_type_id)
    
    case issue_type['name']
    when "Epic"
      issue[:fields][@meta_data.epic_name_field] = issue[:fields][:summary]
    when "Story"
      if data.send_initiatives == "1"
        if initiative
          issue[:fields][@meta_data.epic_link_field] = find_or_create_epic_from_initiative(initiative)
        end
      else
        issue[:fields][@meta_data.epic_link_field] = parent['key'] if parent
      end
    end
    if parent and issue_type['subtask']
      issue[:fields][:parent] = {key: parent['key']}
    end
  end
  
  def issue_type(issue_type_id)
    raise AhaService::RemoteError, "Integration has not been configured" if @meta_data.projects.nil?
    project = @meta_data.projects.find {|project| project['key'] == data.project }
    raise AhaService::RemoteError, "Integration has not been configured, can't find project '#{data.project}'" if project.nil?
    issue_type = project.issue_types.find {|type| type.id.to_s == issue_type_id.to_s }
    raise AhaService::RemoteError, "Integration needs to be reconfigured, issue types have changed, can't find issue type '#{issue_type_id}'" if issue_type.nil?
    issue_type
  end
  
  # Convert HTML from Aha! into Confluence-style wiki markup.
  def convert_html(html)
    parser = HTMLToConfluenceParser.new
    parser.feed(html)
    parser.to_wiki_markup
  end

  def integrate_release_with_jira_version(release, version)
    api.create_integration_field("releases", release.reference_num, self.class.service_name, :id, version['id'])
  end

  def integrate_resource_with_jira_issue(resource_type, resource, issue)
    api.create_integration_field(resource_type, resource.id, self.class.service_name, :id, issue['id'])
    api.create_integration_field(resource_type, resource.id, self.class.service_name, :key, issue['key'])
    api.create_integration_field(resource_type, resource.id, self.class.service_name, :url, "#{data.server_url}/browse/#{issue['key']}")
  end
  
end
