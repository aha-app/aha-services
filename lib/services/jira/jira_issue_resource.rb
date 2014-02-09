class JiraIssueResource < JiraResource
  def find_by_id_and_version(id, version)
    prepare_request
    response = http_get "#{api_url}/issue/#{id}"
    issue = (response.status == 200 ? parse(response.body) : nil)
    issue if issue && issue['fields'] && issue['fields']['project'] &&
      (issue['fields']['project']['id'] == @service.data.project) &&
      issue['fields']['fixVersions'] &&
      issue['fields']['fixVersions']['id'] == version['id']
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
