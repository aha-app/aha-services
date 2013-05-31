class AhaServices::Jira < AhaService
  string :server_url
  string :username
  password :password
  
  callback_url
  
  def receive_installed
    projects = []
    
    prepare_request
    response = http_get '%s/rest/api/2/issue/createmeta' % [data.server_url]
    process_response(response, 200) do |meta|      
      meta['projects'].each do |project|
        issue_types = []
        project['issuetypes'].each do |issue_type|
          issue_types << {:id => issue_type['id'], :name => issue_type['name']}
        end
        projects << {:id => project['id'], :key => project['key'], :name => project['name'], :issue_types => issue_types}
      end
    end
    
    @meta_data.projects = projects
  end
  
  def receive_create_feature
    create_jira_issue(payload.feature, "DEMO")
  end
  
  def create_jira_issue(feature, project_key)
    issue = {
      fields: {
        project: {key: project_key},
        summary: feature.name,
        description: convert_html(feature.description.body),
        issuetype: {id: 1}
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
      api.create_integration_field(feature.reference_num, :jira, :url, new_issue["self"])
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
  
end
