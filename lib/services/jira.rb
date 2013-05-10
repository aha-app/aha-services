class Service::Jira < Service
  
  def receive_create_feature
    http.headers['Content-Type'] = 'application/json'
    res = http_post "https://foo.com/a/rest/api/a/issue", "body"
  end
  
end