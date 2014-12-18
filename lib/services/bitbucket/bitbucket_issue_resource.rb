class BitbucketIssueResource < BitbucketResource
  def find_by_id_and_milestone(id, milestone)
    prepare_request
    response = http_get "#{bitbucket_issues_path}/#{id}"
    issue = found_resource(response)
    issue if issue && issue['metadata'] && (issue['metadata']['milestone'] == milestone['name'])
  end

  def create(new_issue)
    prepare_request
    response = http_post bitbucket_issues_path, new_issue.to_query, {
      'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8'
    }
    process_response(response, 200) do |issue|
      return issue
    end
  end

  def update(number, updated_issue)
    prepare_request
    response = http_put "#{bitbucket_issues_path}/#{number}", updated_issue.to_query, {
      'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8'
    }
    process_response(response, 200) do |issue|
      return issue
    end
  end

private

  def bitbucket_issues_path
    "#{API_URL}/repositories/#{@service.data.repository}/issues"
  end
end
