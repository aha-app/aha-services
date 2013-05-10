class Service::Jira < Service
  string   :server_url, :api_version, :username
  password :password
  
  def receive_create_feature
    http.headers['Content-Type'] = 'application/json'
    res = http_post '%s/rest/api/%s/issue' % [data['server_url'], data['api_version']], "body"
  end
  
end