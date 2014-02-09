class JiraIssueLinkResource < JiraResource
  def create(link)
    prepare_request
    response = http_post "#{api_url}/issueLink", link.to_json
    process_response(response, 201)
  end
end
