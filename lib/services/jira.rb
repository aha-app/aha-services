require 'html2confluence'

class AhaServices::Jira < AhaService
  title "JIRA"
  caption "Send features to JIRA issue tracking (supports on-premise and cloud)"
  
  string :server_url, description: "URL for the JIRA server, without the trailing slash, e.g. https://bigaha.atlassian.net"
  string :username, description: "Use your JIRA username from the JIRA profile page, not your email address."
  password :password
  install_button
  select :project, collection: ->(meta_data, data) { meta_data.projects.collect{|p| [p.name, p[:key]] } },
    description: "Choose the JIRA project to integrate with, then click 'Load project data' to fetch the configuration for that project.",
    configure_button: "Load project data",
    configure_button_highlight_if: -> (meta_data, data) { meta_data["configuration"]["attribute_project"]["project"] != data["project"] rescue true }
  boolean :send_initiatives, description: "Check to use feature initiatives to create Epics in JIRA Agile"
  select :feature_issue_type, 
    collection: ->(meta_data, data) { 
      meta_data.issue_type_sets[meta_data.projects.detect {|p| p[:key] == data.project}.issue_types].find_all{|i| !i.subtype}.collect{|p| [p.name, p.id] }
    }, description: "JIRA issue type that will be used when sending features. If you are using JIRA Agile then we recommend 'Story'."
  select :requirement_issue_type, 
    collection: ->(meta_data, data) { 
      meta_data.issue_type_sets[meta_data.projects.detect {|p| p[:key] == data.project}.issue_types].find_all{|i| !i.subtype}.collect{|p| [p.name, p.id] }
    }, description: "JIRA issue type that will be used when sending requirements. If you are using JIRA Agile then we recommend 'Sub-task'."
  internal :feature_status_mapping
  internal :field_mapping
  # internal :resolution_mapping  # TODO: we are not actually using this at the moment.
  boolean :dont_send_releases, description: "Check to prevent Aha! from creating versions in JIRA and from populating the fixVersions field for issues. For most users this box should not be checked."
  
  boolean :dont_auto_import, description: "Check to prevent Aha! from automatically importing issues that are related to an issue that is already linked to Aha!"
  boolean :only_auto_import_mapped_issue_types, description: "Check to prevent Aha! from from automatically importing issue types that are not mapped to Features or Requirements"

  boolean :send_tags, description: "Check to synchronize Aha! tags and JIRA labels. We recommend enabling this for new integrations. Enabling this option once features are synced to JIRA may cause tags in Aha! or labels in JIRA to be removed from a feature if the corresponding label or tag doesn't exist in the other system."
  
  callback_url description: "The webhook enables updates from JIRA to Aha! Follow the instructions above to install this webhook in JIRA. Only one hook is necessary, even if multiple products are integrated with JIRA."
    
  def receive_installed
    get_common_configuration
  end

  def receive_configured
    case payload[:field]
    when "attribute_project"
      get_common_configuration
      
      if data.project && projects = @meta_data["projects"].detect{|project| project['key'] == data.project}
        project_id = projects["id"]
        project_resource.fetch_expanded_data_for_project(project_id, @meta_data)
      end

      @meta_data["configuration"] = {
        "attribute_project" => {
          "project" => data.project,
          "message" => "Loaded configuration for project #{data.project}",
          "success" => true
        }
      }
      @meta_data
    end
  end

  def receive_create_feature
    integrate_or_update_feature(payload.feature)
  end
  
  def receive_update_feature
    integrate_or_update_feature(payload.feature)
  end

  def receive_create_requirement
    integrate_or_update_requirement(payload.requirement)
  end

  def receive_update_requirement
    integrate_or_update_requirement(payload.requirement)
  end

  def receive_create_release
    find_or_attach_jira_version(payload.release) unless dont_send_releases?
  end
  
  def receive_update_release
    update_or_attach_jira_version(payload.release) unless dont_send_releases?
  end
  
  def receive_create_comment
    create_comment(payload.comment, payload.commentable)
  end

  # These methods are exposed here so they can be used in the callback and
  # import code.
  def get_issue(issue_id)
    issue_resource.find_by_id(issue_id, expand: "renderedFields")
  end

  def get_attachment(attachment)
    attachment_resource.download(attachment)
  end

  def search_issues(params)
    issue_resource.search(params)
  end

  def issue_type_by_id(id)
    raise AhaService::RemoteError, "Integration has not been configured" if meta_data.projects.nil?
    project = meta_data.projects.find {|project| project[:key] == data.project }
    raise AhaService::RemoteError, "Integration has not been configured, can't find project '#{data.project}'" if project.nil?
    raise AhaService::RemoteError, "Integration has not been configured, project data not loaded" if meta_data.issue_type_sets.nil?
    issue_types = meta_data.issue_type_sets[project.issue_types]
    issue_type = issue_types.find {|type| type.id.to_s == id.to_s }
    raise AhaService::RemoteError, "Integration needs to be reconfigured, issue types have changed, can't find issue type '#{id}'" if issue_type.nil?
    issue_type
  end

  def update_issue_fields(issue_id, issue)
    issue_resource.update(issue_id, issue)
  end


protected
  include JiraMappedFields
  
  def get_common_configuration
    @meta_data ||= {}
    @meta_data['epic_name_field'] = field_resource.epic_name_field
    @meta_data['epic_link_field'] = field_resource.epic_link_field
    @meta_data['story_points_field'] = field_resource.story_points_field
    @meta_data['aha_position_field'] = field_resource.aha_position_field
    @meta_data['aha_reference_field'] = new_or_existing_aha_reference_field
    @meta_data["projects"] = project_resource.list
    @meta_data['resolutions'] = resolution_resource.all
  end
  
  def dont_send_releases?
    data.dont_send_releases == "1"
  end
  
  def new_or_existing_aha_reference_field
    # Create custom field for Aha! reference.
    unless field = field_resource.aha_reference_field
      field = field_resource.create(
        name: "Aha! Reference",
        description: "Link to the Aha! item this issue is related to.",
        type: "com.atlassian.jira.plugin.system.customfieldtypes:url"
      ).tap do |new_field|
        # Add field to the default screen.
        field_resource.add_to_default_screen(new_field)
      end
    end
    field
  end

  def integrate_or_update_feature(feature)
    @feature = feature
    version = find_or_attach_jira_version(feature.release) unless dont_send_releases?
    issue_info = update_or_attach_jira_issue(feature, feature.initiative, version)
    update_requirements(feature, version, issue_info)
  end

  def find_or_attach_jira_version(release)
    if version = existing_version_integrated_with(release)
      version
    else
      attach_version_to(release)
    end
  end
  
  def update_or_attach_jira_version(release)
    if version_id = get_integration_field(release.integration_fields, 'id') and
        version = existing_version_integrated_with(release)
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
    logger.info("Creating version for #{release.reference_num}")
    version_resource.create name: release.name,
                            description: "Created from Aha! #{release.url}",
                            releaseDate: release.release_date,
                            released: release.released
  end

  def update_version(id, release)
    logger.info("Updating version for #{release.reference_num}")
    version_resource.update id, name: release.name,
                                releaseDate: release.release_date,
                                released: release.released
  end
  
  def update_requirements(feature, version, issue_info)
    if feature.requirements
      feature.requirements.each do |requirement|
        update_or_attach_jira_issue(requirement, nil, version, issue_info)
      end
    end
  end

  def integrate_or_update_requirement(requirement)
    @feature = requirement.feature
    version = find_or_attach_jira_version(@feature.release) unless dont_send_releases?
    issue_info = get_existing_issue_info(@feature)
    jira_requirement = update_or_attach_jira_issue(requirement, nil, version, issue_info)
    logger.info("Created/Updated issue #{jira_requirement[:key]} with requirement #{requirement.reference_num}")
  end

  def get_existing_issue_info(resource)
    if id = get_integration_field(resource.integration_fields, 'id') and
      key = get_integration_field(resource.integration_fields, 'key')
      Hashie::Mash.new(id: id, key: key)
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
    issue = create_issue_for(resource, initiative, version, parent)
    integrate_resource_with_jira_issue(reference_num_to_resource_type(resource.reference_num), resource, issue)

    # Put the issue in the correct order.
    set_issue_rank(issue, resource)    

    # Add attachments.
    upload_attachments(resource.description.attachments, issue.id)
    upload_attachments(resource.attachments, issue.id)

    issue
  end
  
  # Create an epic from an initiative, or find an existing epic for the 
  # initiative.
  #
  # Note there is a possible race condition - if multiple features with the
  # same initiative are being created in parallel then duplicate initiatives
  # can be created. We avoid this by creating multiple features synchronously 
  # in the application. 
  def epic_key_for_initiative(initiative)
    if epic_key = get_integration_field(initiative.integration_fields, 'key')
      epic_key
    elsif issue_type = epic_issue_type
      create_issue_for_initiative(initiative, issue_type)[:key]
    end
  end
  
  def create_issue_for_initiative(initiative, issue_type)
    logger.info("Creating issue for initiative #{initiative.id}")
    
    issue = Hashie::Mash.new(
      fields: {
        summary: resource_name(initiative),
        description: convert_html(initiative.description.body),
        issuetype: { id: issue_type.id },
        meta_data.epic_name_field => initiative.name
      }
    )
    issue.fields.merge!(aha_reference_fields(initiative, issue_type))

    new_issue = issue_resource.create(issue)
    upload_attachments(initiative.description.attachments, new_issue.id)
    integrate_initiative_with_jira_issue(initiative, new_issue)

    logger.info("Created issue #{new_issue[:key]}")

    new_issue
  end

  def create_issue_for(resource, initiative, version, parent)
    issue_type = issue_type_by_parent(parent)
    summary = resource_name(resource)
    
    logger.info("Creating issue for #{resource.reference_num}")
    
    issue = Hashie::Mash.new(
      fields: {
        summary: summary,
        description: convert_html(resource.description.body),
        issuetype: {id: issue_type.id}
      }
    )
    issue.fields
      .merge!(version_fields(version, issue_type))
      .merge!(label_fields(resource, issue_type))
      .merge!(aha_reference_fields(resource, issue_type))
      .merge!(issue_epic_name_field(issue_type, summary))
      .merge!(issue_epic_link_field(issue_type, parent, initiative))
      .merge!(subtask_fields(issue_type.subtask, parent))
      .merge!(time_tracking_fields(resource, issue_type))
      .merge!(assignee_fields(resource, issue_type))
      .merge!(reporter_fields(resource, issue_type))
      .merge!(aha_position_fields(resource, issue_type))

    # Use the custom fields from @feature to populate requirements, to solve for required custom fields on create
    issue.fields.merge!(mapped_custom_fields(@feature, issue_type))
    issue.fields.merge!(due_date_fields(@feature, issue_type))
    
    new_issue = issue_resource.create(issue)

    create_link_for_issue(new_issue, issue_type, parent)
    
    logger.info("Created issue #{new_issue[:key]}")
    
    new_issue
  end

  def update_issue(issue_info, resource, initiative, version, parent)
    issue_type = issue_type_by_parent(parent)

    logger.info("Updating issue #{issue_info[:key]} with #{resource.reference_num}")

    summary = resource_name(resource)
    issue = Hashie::Mash.new(
      fields: {
        summary: summary,
        description: convert_html(resource.description.body)
      }
    )
    
    #   .merge!(subtask_fields(issue_type.subtask, parent)) # This is not possible for updates.
    # We do still generate the epic link field since it creates the initiative
    # in JIRA, though it doesn't link it.
    issue_epic_link_field(issue_type, parent, initiative)
    
    issue.fields
      .merge!(label_fields(resource, issue_type))
      .merge!(time_tracking_fields(resource, issue_type))
      .merge!(aha_reference_fields(resource, issue_type))
      .merge!(assignee_fields(resource, issue_type))
      .merge!(aha_position_fields(resource, issue_type))

    if @feature == resource
      # Only update custom_fields and due dates for features, not requirements.
      # This will cause an issue with two-way field syncing if we constantly overwrite requirements' custom fields
      issue.fields
        .merge!(mapped_custom_fields(@feature, issue_type))
        .merge!(due_date_fields(@feature, issue_type))
    end
      
    issue.merge!(version_update_fields(version, issue_type))

    issue_resource.update(issue_info.id, issue)

    update_epic_link(issue_info.id, issue_type, parent, initiative)
    
    update_attachments(issue_info.id, resource)
    
    issue_info
  rescue Errors::RemoteError => e
    if e.message =~ /You do not have permission to edit issues/
      # Ignore permission errors. They happen when we try to update an issue
      # that was already closed.
      issue_info
    else
      raise e
    end
  end

  def create_link_for_issue(issue, issue_type, parent)
    if parent and !issue_type.subtask and !issue_type_by_parent(nil).has_field_epic_name
      link = {
        type: {
          name: "Relates"
        },
        outwardIssue: {
          id: issue.id
        },
        inwardIssue: {
          id: parent.id
        }
      }
      issue_link_resource.create(link)
    end
  end
  
  def create_comment(comment, resource)
    issue_info = get_existing_issue_info(resource)
    
    logger.info("Creating comment for #{issue_info.id}")
    
    comment_hash = Hashie::Mash.new(
      body: "Comment added by #{comment.user.name} in [Aha!|#{comment.url}]\n\n" + convert_html(comment.body)
    )
    new_comment = comment_resource.create(issue_info.id, comment_hash)
    
    upload_attachments(comment.attachments, issue_info.id)
    
    new_comment
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
  
  def comment_resource
    @comment_resource ||= JiraCommentResource.new(self)
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

  def user_resource
    @user_resource ||= JiraUserResource.new(self)
  end
  
  def greenhopper_epic_resource
    @greenhopper_epic_resource ||= GreenhopperEpicResource.new(self)
  end
  
  def update_attachments(issue_id, resource)
    aha_attachments = resource.attachments.dup | resource.description.attachments.dup

    # Create any attachments that didn't already exist.
    upload_attachments(new_aha_attachments(aha_attachments, issue_id), issue_id)
  end

  def new_aha_attachments(aha_attachments, issue_id)
    attachment_resource.all_for_issue(issue_id).each do |jira_attachment|
      # Remove any attachments that match.
      aha_attachments.reject! do |aha_attachment|
        attachments_match(aha_attachment, jira_attachment)
      end
    end

    aha_attachments
  end

  def attachments_match(aha_attachment, jira_attachment)
    aha_attachment.file_name == jira_attachment.filename &&
      aha_attachment.file_size.to_i == jira_attachment[:size].to_i
  end

  def upload_attachments(attachments, issue_id)
    attachments.each do |attachment|
      attachment_resource.upload(attachment, issue_id)
    end
  end

  def version_fields(version, issue_type)
    if !dont_send_releases? && version && version.id && issue_type.has_field_fix_versions
      { fixVersions: [{ id: version.id }] }
    else
      Hash.new
    end
  end

  def label_fields(resource, issue_type)
    if data.send_tags == "1" and resource.tags and issue_type.has_field_labels
      { labels: resource.tags }
    else
      Hash.new
    end
  end
  
  def due_date_fields(resource, issue_type)
    if issue_type.fields.include?('duedate') and resource.due_date
      { duedate: resource.due_date }
    else
      Hash.new
    end
  end

  def aha_reference_fields(resource, issue_type)
    if issue_type.has_field_aha_reference
      { meta_data.aha_reference_field => resource.url }
    else
      Hash.new
    end
  end

  def aha_position_fields(resource, issue_type)
    if issue_type.has_field_aha_position
      { meta_data.aha_position_field => resource.position }
    else
      Hash.new
    end
  end

  def assignee_fields(resource, issue_type)
    if (issue_type.has_field_assignee.nil? || issue_type.has_field_assignee) && resource.assigned_to_user && !resource.assigned_to_user.default_assignee && (user = user_resource.picker(resource.assigned_to_user.email))
      { assignee: { name: user.name } }
    else
      Hash.new
    end
  end
  
  def reporter_fields(resource, issue_type)
    if (issue_type.has_field_reporter.nil? || issue_type.has_field_reporter) && resource.created_by_user && (user = user_resource.picker(resource.created_by_user.email))
      { reporter: { name: user.name } }
    else
      Hash.new
    end
  end

  def time_tracking_fields(resource, issue_type)
    # Don't send updates to JIRA if capacity planning is disabled.
    return Hash.new unless resource.key?('original_estimate')
    
    if resource.use_requirements_estimates == true
      # Don't include feature estimate if requirements have estimates.
      return Hash.new
    end
    
    if resource.work_units == 10 and issue_type.has_field_time_tracking and 
      (resource.original_estimate.nil? or resource.original_estimate <= 20000) and 
      (resource.remaining_estimate.nil? or resource.remaining_estimate <= 20000) # Units are minutes. Ensure estimates are below the max limit for Jira
      {
        timetracking: {
          originalEstimate: resource.original_estimate,
          remainingEstimate: resource.remaining_estimate
        }
      }
    elsif resource.work_units == 20 and issue_type.has_field_story_points # Units are points.
      { meta_data.story_points_field => resource.original_estimate }
    else
      Hash.new
    end
  end
  
  def issue_epic_name_field(issue_type, summary)
    if issue_type.has_field_epic_name
      { meta_data.epic_name_field => summary }
    else
      Hash.new
    end
  end

  def issue_epic_link_field(issue_type, parent, initiative)
    if data.send_initiatives == "1" && initiative && issue_type.has_field_epic_link
      { meta_data.epic_link_field => epic_key_for_initiative(initiative) }
    # Check if parent exists and that it is actually an epic.
    elsif parent && issue_type.has_field_epic_link && issue_type_by_id(data.feature_issue_type).has_field_epic_name
      { meta_data.epic_link_field => parent[:key] }
    else
      Hash.new
    end
  end
  
  def update_epic_link(issue_id, issue_type, parent, initiative)
    epic_key = nil
    if data.send_initiatives == "1" && initiative && issue_type.has_field_epic_link
      epic_key = epic_key_for_initiative(initiative)
    # Check if parent exists and that it is actually an epic.
    elsif parent && issue_type.has_field_epic_link && issue_type_by_id(data.feature_issue_type).has_field_epic_name
      epic_key = parent[:key]
    end
    if epic_key
      greenhopper_epic_resource.add_story(issue_id, epic_key) 
    elsif data.send_initiatives == "1" && initiative.nil? && issue_type.has_field_epic_link
      begin
        issue_data = get_issue(issue_id)
        if issue_data && (epic_key = issue_data.fields[meta_data.epic_link_field])
          greenhopper_epic_resource.remove_story(issue_id, epic_key) 
        end
      rescue Exception => e
        logger.debug("Error removing epic from issue. #{e.class}: #{e.message} #{e.backtrace.join("\n")}")
      end
    end
  end

  def subtask_fields(is_subtask, parent)
    if parent and is_subtask
      { parent: { key: parent[:key] } }
    else
      Hash.new
    end
  end

  def version_update_fields(version, issue_type)
    if !dont_send_releases? && version && version.id && issue_type.has_field_fix_versions
      { update: { fixVersions: [ { set: [ { id: version.id } ] } ] } }
    else
      Hash.new
    end
  end
  
  def set_issue_rank(issue, resource)
    # Call back into Aha! to find another issue to rank relative to.
    adjacent_info = api.adjacent_integration_fields(
      reference_num_to_resource_type(resource.reference_num), resource.id, data.integration_id).first
    if adjacent_info
      adjacent_issue_id = get_integration_field(adjacent_info.integration_fields, 'id')    
      issue_resource.set_rank(issue[:key], adjacent_issue_id, adjacent_info.direction == "before" ? :before : :after) 
    end
  end
  
  def issue_type_by_parent(parent)
    issue_type_id = parent ? (data.requirement_issue_type || data.feature_issue_type) : data.feature_issue_type
    issue_type_by_id(issue_type_id)
  end


  def epic_issue_type
    raise AhaService::RemoteError, "Integration has not been configured" if meta_data.projects.nil?
    project = meta_data.projects.find {|project| project[:key] == data.project }
    raise AhaService::RemoteError, "Integration has not been configured, can't find project '#{data.project}'" if project.nil?
    issue_types = meta_data.issue_type_sets[project.issue_types]
    issue_types.find {|type| type.has_field_epic_name == true }
  end
  
  # Convert HTML from Aha! into Confluence-style wiki markup.
  def convert_html(html)
    parser = HTMLToConfluenceParser.new
    parser.feed(html)
    parser.to_wiki_markup
  end

  def integrate_release_with_jira_version(release, version)
    api.create_integration_fields("releases", release.reference_num, data.integration_id, 
    {id: version.id, url: "#{data.server_url}/browse/#{data.project}/fixforversion/#{version.id}"})
  end

  def integrate_resource_with_jira_issue(resource_type, resource, issue)
    api.create_integration_fields(resource_type, resource.id, data.integration_id,
      {url: "#{data.server_url}/browse/#{issue[:key]}", id: issue.id, key: issue[:key]})
  end

  def integrate_initiative_with_jira_issue(initiative, issue)
    integrate_resource_with_jira_issue("initiatives", initiative, issue)

    # Add our newly created integration field so multiple initiatives aren't created, when an initiative is not already synced to jira
    initiative.integration_fields << Hashie::Mash.new("name" => "key", "value" => issue[:key], "integration_id" => self.data.integration_id.to_s)

  rescue AhaApi::BadRequest
    # Failure was probably due to initiative from another product, convert
    # to a more user friendly message.
    raise AhaService::RemoteError,
      "Initiative '#{initiative.name}' is from a product without a JIRA integration. Add a JIRA integration for the product the initiative belongs to."
  end
  
end
