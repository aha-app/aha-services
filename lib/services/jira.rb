class Service::Jira < Service
  string   :server_url, :api_version, :username
  password :password
  
  def receive_create_feature
    create_jira_issue(payload.feature, "DEMO")
  end
  
  def create_jira_issue(feature, project_key)
    issue = {
      fields: {
        project: {key: project_key},
        summary: feature.name,
        description: feature.description,
        issuetype: {id: 1}
      }
    }
    http.headers['Content-Type'] = 'application/json'
    http.basic_auth data['username'], data['password']
    response = http_post '%s/rest/api/%s/issue' % [data['server_url'], data['api_version']], issue.to_json
    if response.status == 201
      new_issue = parse(response.body)
      
      issue_id = new_issue["id"]
      issue_key = new_issue["key"]
      puts "Created issue #{issue_id} / #{issue_key}"
      
      api.create_connection_field(feature.reference_num, :jira, :id, new_issue["id"])
      api.create_connection_field(feature.reference_num, :jira, :key, new_issue["key"])
      
    elsif response.status == 400
      errors = parse(response.body)
      error_string = errors["errorMessages"].join(", ") + 
        errors["errors"].map {|k, v| "#{k}: #{v}" }.join(", ")
      
      puts "Error: #{error_string}"
    end
  end

  def parse(body)
    if body.nil? or body.length < 2
      {}
    else
      JSON.parse(body)
    end
  end
  
end
