require 'html2confluence'
require 'open-uri'

class AhaServices::Jira < AhaService
  string :server_url, description: "URL for the Jira server, without the trailing slash, e.g. https://bigaha.atlassian.net"
  string :username
  password :password
  select :project, collection: ->(meta_data, data) { meta_data.projects.collect{|p| [p.name, p['key']] } }
  select :feature_issue_type, 
    collection: ->(meta_data, data) { 
      meta_data.projects.detect {|p| p['key'] == data.project}.issue_types.collect{|p| [p.name, p.id] } 
    }, description: "Issue type to use for features."
  internal :feature_status_mapping
  select :requirement_issue_type, collection: ->(meta_data, data) { 
    meta_data.projects.detect {|p| p['key'] == data.project}.issue_types.collect{|p| [p.name, p.id] } 
  }, description: "Issue type to use for requirements - this should be a sub-type of the feature issue type."
  internal :requirement_status_mapping
  internal :resolution_mapping
  
  callback_url description: "URL to add to the webhooks section of Jira."
  
  def receive_installed
    logger.info("DATA: #{data.inspect}")
    
    prepare_request
    response = http_get '%s/rest/api/2/issue/createmeta' % [data.server_url]
    projects = []
    process_response(response, 200) do |meta|      
      meta['projects'].each do |project|
        issue_types = []
        
        # Get the statuses.
        status_response = http_get '%s/rest/api/2/project/%s/statuses' % [data.server_url, project['key']]
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
    feature_id = create_jira_issue(data.feature_issue_type, payload.feature, data.project)
    payload.feature.requirements.each do |requirement|
      # TODO: don't create requirements that have been dropped.
      create_jira_issue(data.requirement_issue_type, requirement, data.project, feature_id)
    end
  end

protected

  def create_jira_issue(issue_type, resource, project_key, parent = nil)
    issue_id = nil
    issue_key = nil
    
    issue = {
      fields: {
        project: {key: project_key},
        summary: resource.name || "Requirement #{resource.reference_num}",
        description: append_link(convert_html(resource.description.body), resource),
        issuetype: {id: issue_type}
      }
    }
    issue[:fields][:parent] = {id: parent} if parent
    
    prepare_request
    response = http_post '%s/rest/api/2/issue' % [data.server_url], issue.to_json 
    process_response(response, 201) do |new_issue|      
      issue_id = new_issue["id"]
      issue_key = new_issue["key"]
      logger.info("Created issue #{issue_id} / #{issue_key}")
      
      api.create_integration_field(resource.reference_num, :jira, :id, issue_id)
      api.create_integration_field(resource.reference_num, :jira, :key, issue_key)
      api.create_integration_field(resource.reference_num, :jira, :url, "#{data.server_url}/browse/#{issue_key}")
    end
    
    # Add attachments.
    resource.description.attachments.each do |attachment|
      upload_attachment(attachment, issue_id)
    end
    
    issue_id
  end

  def upload_attachment(attachment, issue_id)
    open(attachment.download_url) do |downloaded_file|
      # Reset Faraday and switch to multipart to do the file upload.
      http_reset 
      http(:encoding => :multipart)
      http.headers['X-Atlassian-Token'] = 'nocheck'
      http.basic_auth data.username, data.password
      
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
    "#{body}\n\nCreated from [#{resource.reference_num}|#{resource.url}] in Aha!"
  end
  
end
