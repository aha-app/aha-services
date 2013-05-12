class Service::Jira < Service
  string   :server_url, :api_version, :username
  password :password
  
  def receive_create_feature
    create_jira_issue("Sample issue name", "Sample issue description", "DEMO")
  end
  
  def create_jira_issue(name, description, project_key)
    issue = {
      fields: {
        project: {key: project_key},
        summary: name,
        description: description,
        issueType: {id: 1}
      }
    }
    http.headers['Content-Type'] = 'application/json'
    res = http_post '%s/rest/api/%s/issue' % [data['server_url'], data['api_version']], issue.to_json
  end
  
end