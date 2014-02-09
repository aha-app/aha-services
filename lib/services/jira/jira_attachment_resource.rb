class JiraAttachmentResource < JiraResource
  def all_for_issue(issue_id)
    prepare_request
    response = http_get "#{api_url}/issue/#{issue_id}?fields=attachment"
    process_response(response, 200) do |issue|
      return issue['fields']['attachment']
    end
  end

  def upload

  end
end
