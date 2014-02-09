require 'html2confluence'
require 'open-uri'

class AhaServices::Jira < AhaService
  title "JIRA"
  
  string :server_url, description: "URL for the JIRA server, without the trailing slash, e.g. https://bigaha.atlassian.net"
  string :username, description: "Use your JIRA username from the JIRA profile page, not your email address."
  password :password
  install_button
  select :project, collection: ->(meta_data, data) { meta_data.projects.collect{|p| [p.name, p['key']] } }
  select :feature_issue_type, 
    collection: ->(meta_data, data) { 
      meta_data.projects.detect {|p| p['key'] == data.project}.issue_types.find_all{|i| !i['subtype']}.collect{|p| [p.name, p.id] } 
    }, description: "JIRA issue type that will be used when sending features. If you are using JIRA Agile then we recommend 'Epic'."
  select :requirement_issue_type, 
    collection: ->(meta_data, data) { 
      meta_data.projects.detect {|p| p['key'] == data.project}.issue_types.find_all{|i| !i['subtype']}.collect{|p| [p.name, p.id] } 
    }, description: "JIRA issue type that will be used when sending requirements. If you are using JIRA Agile then we recommend 'Story'."
  internal :feature_status_mapping
  internal :resolution_mapping
  
  callback_url description: "URL to add to the webhooks section of JIRA. Only one hook is necessary, even if multiple products are integrated with JIRA."
  
  def receive_installed
    @meta_data.projects = project_resource.all
    
    @meta_data.resolutions = resolution_resource.all

    # Get custom field mappings.
    @meta_data.epic_name_field = field_resource.epic_name_field
    @meta_data.epic_link_field = field_resource.epic_link_field
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
    find_or_attach_jira_issue(payload.feature, version)
    update_requirements(payload.feature, version)
  end
  
  def receive_update_feature
    version = find_or_attach_jira_version(payload.feature.release)
    update_or_attach_jira_issue(payload.feature, version)
    update_requirements(payload.feature, version)
  end

  def receive_create_release
    find_or_attach_jira_version(payload.release)
  end
  
  def receive_update_release
    update_or_attach_jira_version(payload.release)
  end

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

  def existing_issue_integrated_with(resource, version)
    if issue_id = get_integration_field(resource.integration_fields, 'id')
      issue_resource.find_by_id_and_version(issue_id, version)
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
  
  def update_requirements(feature, version)
    if feature.requirements
      feature.requirements.each do |requirement|
        update_or_attach_jira_issue(requirement, version, feature)
      end
    end
  end

  def find_or_attach_jira_issue(resource, version, parent = nil)
    if issue = existing_issue_integrated_with(resource, version)
      issue
    else
      attach_issue_to(resource, version, parent)
    end
  end

  def update_or_attach_jira_issue(resource, version, parent = nil)
    if issue_id = get_integration_field(resource.integration_fields, 'id')
      update_issue(issue_id, resource, version)
    else
      attach_issue_to(resource, version, parent)
    end
  end

  def attach_issue_to(resource, version, parent)
    issue = create_issue_for(resource, version, parent)
    integrate_resource_with_jira_issue(resource, issue)

    # Add attachments.
    resource.description.attachments.each do |attachment|
      upload_attachment(attachment, issue['id'])
    end
    resource.attachments.each do |attachment|
      upload_attachment(attachment, issue['id'])
    end

    issue
  end

  def create_issue_for(resource, version, parent)
    issue_id = nil
    issue_key = nil
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
    if @meta_data.aha_reference_field
      issue[:fields][@meta_data.aha_reference_field] = resource.url
    end
    case issue_type['name']
    when "Epic"
      issue[:fields][@meta_data.epic_name_field] = summary
    when "Story"
      issue[:fields][@meta_data.epic_link_field] = parent[:key] if parent
    end
    if parent and issue_type['subtask']
      issue[:fields][:parent] = {key: parent[:key]}
    end

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
          id: parent[:id]
        }
      }
      issue_link_resource.create(link)
    end

    new_issue
  end

  def update_issue(id, resource, version)
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

    issue_resource.update(id, issue)

    update_attachments(id, resource)

    # TODO: Should update epic link field, or issue links if parent feature has
    # changed for a requirement.
  end

protected

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
  
  def update_attachments(issue_id, resource)
    # New list of attachments.
    attachments = resource.attachments.dup | resource.description.attachments.dup
    
    # Get the current attachments.
    prepare_request
    status_response = http_get '%s/rest/api/2/issue/%s?fields=attachment' % [data.server_url, issue_id]
    process_response(status_response, 200) do |issue|      
      issue["fields"]["attachment"].each do |attachment|
        
        # Remove any attachments that match.
        attachments.reject! do |a|
          a.file_name == attachment["filename"] and a.file_size.to_i == attachment["size"].to_i
        end
      end
    end
    
    # Create any attachments that didn't already exist.
    attachments.each do |attachment|
      upload_attachment(attachment, issue_id)
    end
  end
  
  def upload_attachment(attachment, issue_id)
    open(attachment.download_url) do |downloaded_file|
      # Reset Faraday and switch to multipart to do the file upload.
      http_reset 
      http(:encoding => :multipart)
      http.headers['X-Atlassian-Token'] = 'nocheck'
      auth_header
      
      file = Faraday::UploadIO.new(downloaded_file, attachment.content_type, attachment.file_name)
      response = http_post '%s/rest/api/2/issue/%s/attachments' % [data.server_url, issue_id], {:file => file} 
      process_response(response, 200) do
        # Success.
      end
    end
        
  rescue AhaService::RemoteError => e
    logger.error("Failed to upload attachment to #{issue_key}: #{e.message}")
  ensure
    http_reset
    prepare_request
  end
  
  def parse(body)
    if body.nil? or body.length < 2
      {}
    else
      JSON.parse(body)
    end
  end
  
  def prepare_request
    http.headers['Content-Type'] = 'application/json'
    auth_header
  end
  
  def auth_header
    http.basic_auth data.username, data.password
  end
  
  def process_response(response, *success_codes, &block)
    if success_codes.include?(response.status)
      yield parse(response.body)
    elsif response.status == 401 || response.status == 403
      raise AhaService::RemoteError, "Authentication failed: #{response.status} #{response.headers['X-Authentication-Denied-Reason']}"
    elsif response.status == 400
      errors = parse(response.body)
      error_string = errors["errorMessages"].join(", ") + 
        errors["errors"].map {|k, v| "#{k}: #{v}" }.join(", ")
      raise AhaService::RemoteError, "Data not accepted: #{error_string}"
    else
      raise AhaService::RemoteError, "Unhandled error: STATUS=#{response.status} BODY=#{response.body}"
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
    api.create_integration_field(release.reference_num, self.class.service_name, :id, version['id'])
  end

  def integrate_resource_with_jira_issue(resource, issue)
    api.create_integration_field(resource.reference_num, self.class.service_name, :id, issue['id'])
    api.create_integration_field(resource.reference_num, self.class.service_name, :key, issue['key'])
    api.create_integration_field(resource.reference_num, self.class.service_name, :url, "#{data.server_url}/browse/#{issue['key']}")
  end
  
end
