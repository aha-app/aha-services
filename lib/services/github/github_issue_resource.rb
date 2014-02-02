class GithubIssueResource < GithubResource
  def find_by_number_and_milestone(number, milestone)
    prepare_request
    response = http_get "#{github_issues_path}/#{number}"
    issue = (response.status == 200 ? parse(response.body) : nil)
    issue if issue && issue['milestone'] && (issue['milestone']['number'] == milestone['number'])
  end

  def create(new_issue)
    prepare_request
    response = http_post github_issues_path, new_issue.to_json
    process_response(response, 201) do |issue|
      return issue
    end
  end

private

  def github_issues_path
    "#{API_URL}/repos/#{@service.data.username}/#{@service.data.repo}/issues"
  end
end
