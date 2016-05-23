class JiraIssueResource < JiraResource
  def find_by_id(id, params = {})
    prepare_request
    response = http_get "#{api_url}/issue/#{id}?#{params.to_query}"
    issue = found_resource(response)
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
      return issue
    end
  end
  
  def set_rank(issue_id, relative_issue_id, position = :before) 
    prepare_request
    
    rank_info = {issues: [issue_id]}
    if position == :after
      rank_info[:rankBeforeIssue] = relative_issue_id
    else
      rank_info[:rankAfterIssue] = relative_issue_id
    end
    
    response = http_put "#{@service.data.server_url}/rest/agile/1.0/issue/rank", 
      rank_info.to_json
    
    process_response(response, 204)
  rescue Exception => e
    logger.debug("Unable to rank issue #{e.class}: #{e.message} #{e.backtrace.join("\n")}")
  end
end
