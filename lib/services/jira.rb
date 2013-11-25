require 'html2confluence'
require 'open-uri'

class AhaServices::Jira < AhaService
  title "JIRA"
  
  string :server_url, description: "URL for the Jira server, without the trailing slash, e.g. https://bigaha.atlassian.net"
  string :username
  password :password
  install_button
  select :project, collection: ->(meta_data, data) { meta_data.projects.collect{|p| [p.name, p['key']] } }
  select :feature_issue_type, 
    collection: ->(meta_data, data) { 
      meta_data.projects.detect {|p| p['key'] == data.project}.issue_types.find_all{|i| !i['subtype']}.collect{|p| [p.name, p.id] } 
    }, description: "Issue type that will be used for Jira issues."
  internal :feature_status_mapping
  internal :resolution_mapping
  
  callback_url description: "URL to add to the webhooks section of Jira."
  
  def receive_installed
    prepare_request
    response = http_get '%s/rest/api/2/issue/createmeta' % [data.server_url]
    projects = []
    process_response(response, 200) do |meta|      
      meta['projects'].each do |project|
        issue_types = []
        
        # Get the statuses.
        status_response = http_get '%s/rest/api/2/project/%s/statuses' % [data.server_url, project['key']]
        if status_response.status == 404
          # In Jira 5.0 the status is not associated with each issue type.
          status_response = http_get '%s/rest/api/2/status' % [data.server_url]
          process_response(status_response, 200) do |status_meta|      
            statuses = []
            status_meta.each do |status|
              statuses << {:id => status['id'], :name => status['name']}
            end

            project['issuetypes'].each do |issue_type|
              issue_types << {:id => issue_type['id'], :name => issue_type['name'], 
                :subtask => issue_type['subtask'], :statuses => statuses}
            end
          end
        else
          process_response(status_response, 200) do |status_meta|      
            status_meta.each do |issue_type|
              statuses = []
              issue_type['statuses'].each do |status|
                statuses << {:id => status['id'], :name => status['name']}
              end
            
              issue_types << {:id => issue_type['id'], :name => issue_type['name'], 
                :subtask => issue_type['subtask'], :statuses => statuses}
            end
          end
        end
        
        projects << {:id => project['id'], :key => project['key'], 
          :name => project['name'], :issue_types => issue_types}
      end
    end
    @meta_data.projects = projects
    
    response = http_get '%s/rest/api/2/resolution' % [data.server_url]
    resolutions = []
    process_response(response, 200) do |meta|      
      meta.each do |resolution|
        resolutions << {:id => resolution['id'], :name => resolution['name']}
      end
    end
    @meta_data.resolutions = resolutions
    
  end
  
  def receive_create_feature
    version_id = get_jira_id(payload.feature.release.integration_fields)
    unless version_id
      logger.error("Version not created for release #{payload.feature.release.id}")
    end
    
    feature_id = create_jira_issue(payload.feature, data.project, version_id)
    payload.feature.requirements.each do |requirement|
      # TODO: don't create requirements that have been dropped.
      create_jira_issue(requirement, data.project, version_id, feature_id)
    end
  end
  
  def receive_update_feature
    version_id = get_jira_id(payload.feature.release.integration_fields)
    unless version_id
      logger.error("Version not created for release #{payload.feature.release.id}")
    end
    
    feature_id = get_jira_id(payload.feature.integration_fields)
    update_jira_issue(feature_id, payload.feature, version_id)
    
    # Create or update each requirement.
    payload.feature.requirements.each do |requirement|
      requirement_id = get_jira_id(requirement.integration_fields)
      if requirement_id
        # Update requirement.
        update_jira_issue(requirement_id, requirement, version_id)
      else
        # Create new requirement.
        create_jira_issue(requirement, data.project, version_id, feature_id)
      end
    end
  end

  def receive_create_release
    version_id = create_jira_version(payload.release, data.project)
  end
  
  def receive_update_release
    version_id = get_jira_id(payload.release.integration_fields)
    update_jira_version(version_id, payload.release)
  end
  
protected
  
  def create_jira_version(release, project_key)
    version = {
      project: project_key,
      name: release.name,
      description: "Created from Aha! #{release.url}",
      releaseDate: release.release_date,
      released: release.released
    }
          
    prepare_request
    response = http_post '%s/rest/api/2/version' % [data.server_url], version.to_json 
    process_response(response, 201) do |new_version|
      logger.info("Created version #{new_version.inspect}")
      version_id = new_version["id"]
      
      api.create_integration_field(release.reference_num, self.class.service_name, :id, version_id)
    end
  end
  
  def update_jira_version(version_id, release)
    version = {
      id: version_id,
      name: release.name,
      releaseDate: release.release_date,
      released: release.released
    }
          
    prepare_request
    response = http_put '%s/rest/api/2/version/%s' % [data.server_url, version_id], version.to_json 
    process_response(response, 200) do |updated_version|      
      logger.info("Updated version #{version_id}")
    end
  end
  
  def create_jira_issue(resource, project_key, version_id, parent = nil)
    issue_id = nil
    issue_key = nil
    
    issue = {
      fields: {
        project: {key: project_key},
        summary: resource.name || description_to_title(resource.description.body),
        description: append_link(convert_html(resource.description.body), resource),
        issuetype: {id: data.feature_issue_type},
      }
    }
    if version_id
      issue[:fields][:fixVersions] = [{id: version_id}]
    end
          
    prepare_request
    response = http_post '%s/rest/api/2/issue' % [data.server_url], issue.to_json 
    process_response(response, 201) do |new_issue|
      issue_id = new_issue["id"]
      issue_key = new_issue["key"]
      logger.info("Created issue #{issue_id} / #{issue_key}")
      
      api.create_integration_field(resource.reference_num, self.class.service_name, :id, issue_id)
      api.create_integration_field(resource.reference_num, self.class.service_name, :key, issue_key)
      api.create_integration_field(resource.reference_num, self.class.service_name, :url, "#{data.server_url}/browse/#{issue_key}")
    end
    
    # Add attachments.
    resource.description.attachments.each do |attachment|
      upload_attachment(attachment, issue_id)
    end
    resource.attachments.each do |attachment|
      upload_attachment(attachment, issue_id)
    end
    
    # Create links.
    if parent
      link = {
        type: {
          name: "Relates"
        },
        outwardIssue: {
          id: issue_id
        },
        inwardIssue: {
          id: parent
        }
      }
      response = http_post '%s/rest/api/2/issueLink' % [data.server_url], link.to_json 
      process_response(response, 201) do |new_link|
      end
    end
    
    issue_id
  end
  
  def update_jira_issue(issue_id, resource, version_id)
    issue = {
      fields: {
        description: append_link(convert_html(resource.description.body), resource),
      }
    }
    issue[:fields][:summary] = resource.name if resource.name
    if version_id
      issue[:update] ||= {}
      issue[:update][:fixVersions] = [{set: [{id: version_id}]}]
    end
          
    prepare_request
    response = http_put '%s/rest/api/2/issue/%s' % [data.server_url, issue_id], issue.to_json 
    process_response(response, 204) do |updated_issue|      
      logger.info("Updated issue #{issue_id}")
    end
    
    update_attachments(issue_id, resource)
  end

  def update_attachments(issue_id, resource)
    # New list of attachments.
    attachments = resource.attachments.dup | resource.description.attachments.dup
    
    # Get the current attachments.
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
  
  #
  # Get the Jira key from an array of integration fields.
  #
  def get_jira_id(integration_fields)
    return nil if integration_fields.nil?
    field = integration_fields.detect do |f|
      f.service_name == self.class.service_name and f.name == "id"
    end
    if field
      field.value
    else
      nil
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
  
  # Convert HTML from Aha! into Confluence-style wiki markup.
  def convert_html(html)
    parser = HTMLToConfluenceParser.new
    parser.feed(html)
    parser.to_wiki_markup
  end

  def append_link(body, resource)
    "#{body}\n\nCreated from Aha! [#{resource.reference_num}|#{resource.url}]"
  end
  
end
