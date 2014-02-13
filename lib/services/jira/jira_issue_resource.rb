class JiraIssueResource < JiraResource
  def find_by_id(id, params = {})
    prepare_request
    response = http_get "#{api_url}/issue/#{id}?#{params.to_query}"
    issue = (response.status == 200 ? parse(response.body) : nil)
    issue
  end
  
  def search(params = {})
    prepare_request
    response = http_get "#{api_url}/search?#{params.to_query}" 
    process_response(response, 200) do |results|
      return results
    end
  end
  
  def create(new_issue)
    new_issue[:fields].merge!(project: { key: @service.data.project })
    prepare_request
    response = http_post "#{api_url}/issue", new_issue.to_json
    process_response(response, 201) do |issue|
      return issue
    end
  end

  def update(id, updated_issue)
    prepare_request
    response = http_put "#{api_url}/issue/#{id}", updated_issue.to_json
    process_response(response, 204) do |issue|
      logger.info("Updated issue #{id}")
      return issue
    end
  end
end
