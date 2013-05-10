class Service::Jira < Service
  
  def receive_create_feature
    res = http_post "/a/rest/api/a/issue", "body"
  end
  
end