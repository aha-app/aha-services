require 'html2confluence'

class AhaServices::Jira < AhaService
  string :server_url, description: "URL for the Jira server, without the trailing slash, e.g. https://bigaha.atlassian.net"
  string :username
  password :password
  select :project, collection: ->(meta_data, data) { meta_data.projects.collect{|p| [p.name, p['key']] } }
  select :feature_issue_type, 
    collection: ->(meta_data, data) { 
      meta_data.projects.detect {|p| p['key'] == data.project}.issue_types.collect{|p| [p.name, p.id] } 
    }, description: "Issue type to use for features."
  select :feature_complete_status, 
    collection: ->(meta_data, data) { 
      meta_data.projects.detect {|p| p['key'] == data.project}.issue_types.detect {|t| t['id'] == data.feature_issue_type}.statuses.collect{|p| [p.name, p.id] } 
    }, description: "Jira status that indicates a feature is ready to ship."
  select :requirement_issue_type, collection: ->(meta_data, data) { 
    meta_data.projects.detect {|p| p['key'] == data.project}.issue_types.collect{|p| [p.name, p.id] } 
  }, description: "Issue type to use for requirements."
  select :requirement_complete_status, 
    collection: ->(meta_data, data) { 
      meta_data.projects.detect {|p| p['key'] == data.project}.issue_types.detect {|t| t['id'] == data.requirement_issue_type}.statuses.collect{|p| [p.name, p.id] } 
    }, description: "Jira status that indicates a requirement is ready to ship."
  
  callback_url description: "URL to add to the webhooks section of Jira."
  
  def receive_installed
    projects = []
    
    prepare_request
    response = http_get '%s/rest/api/2/issue/createmeta' % [data.server_url]
    process_response(response, 200) do |meta|      
      meta['projects'].each do |project|
        issue_types = []
        #project['issuetypes'].each do |issue_type|
        #  issue_types << {:id => issue_type['id'], :name => issue_type['name'], :subtask => issue_type['subtask']}
        #end
        
        # Get the statuses.
        status_response = http_get '%s/rest/api/2/project/%s/statuses' % [data.server_url, project['key']]
        process_response(status_response, 200) do |status_meta|      
          status_meta.each do |issue_type|
            statuses = []
            issue_type['statuses'].each do |status|
              statuses << {:id => status['id'], :name => status['name']}
            end
            
            issue_types << {:id => issue_type['id'], :name => issue_type['name'], :subtask => issue_type['subtask'], :statuses => statuses}
          end
        end
        
        projects << {:id => project['id'], :key => project['key'], :name => project['name'], :issue_types => issue_types}
      end
    end
    
    @meta_data.projects = projects
  end
  
  def receive_create_feature
    create_jira_issue(payload.feature, data.project)
  end

  def receive_webhook
    if payload.webhookEvent == "jira:issue_updated" && payload.comment
      add_comment(payload.issue.id, payload.comment)
    else
      # Unhandled webhook
    end
  end
  
protected

  def add_comment(issue_id, comment)
    # Find the feature or requirement the issue maps to.
    integration_field = api.search_integration_fields(:jira, :id, issue_id)
    if integration_field
      # TODO: translate body from textile to HTML.
      api.create_comment_with_url(integration_field.object.resource, 
        comment.author.emailAddress, comment.body)
    end
  end

  def create_jira_issue(feature, project_key)
    issue = {
      fields: {
        project: {key: project_key},
        summary: feature.name,
        description: append_link(convert_html(feature.description.body), feature),
        issuetype: {id: data.feature_issue_type}
      }
    }
    prepare_request
    response = http_post '%s/rest/api/2/issue' % [data.server_url], issue.to_json 
    process_response(response, 201) do |new_issue|      
      issue_id = new_issue["id"]
      issue_key = new_issue["key"]
      logger.info("Created issue #{issue_id} / #{issue_key}")
      
      api.create_integration_field(feature.reference_num, :jira, :id, issue_id)
      api.create_integration_field(feature.reference_num, :jira, :key, issue_key)
      api.create_integration_field(feature.reference_num, :jira, :url, "#{data.server_url}/browse/#{issue_key}")
    end
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
      raise AhaService::RemoteError, "Authentication failed: #{response.status}"
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
  
  def append_link(body, feature)
    "#{body}\n\nCreated from Aha! [#{feature.reference_num}|#{feature.url}]."
  end
  
end
