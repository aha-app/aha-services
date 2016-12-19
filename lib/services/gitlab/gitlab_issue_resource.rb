class GitlabIssueResource < GitlabResource
  def find_by_number_and_milestone(number, milestone)
    prepare_request
    response = http_get "#{github_issues_path}/#{number}"
    issue = found_resource(response)
    issue if issue && issue['milestone'] && (issue['milestone']['number'] == milestone['number'])
  end

  def create(new_issue)
    prepare_request
    response = http_post github_issues_path, new_issue.to_json
    process_response(response, 201) do |issue|
      return issue
    end
  end

  def update(number, updated_issue)
    prepare_request
    response = http_patch "#{github_issues_path}/#{number}", updated_issue.to_json
    process_response(response, 200) do |issue|
      return issue
    end
  end

private

  def github_issues_path
    #get_project_id
    "#{ @service.server_url }/projects/#{get_project_id}/issues"
  end
end
