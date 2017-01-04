class GitlabIssueResource < GitlabResource
  def find_by_id_and_milestone(id, milestone)
    prepare_request
    response = http_get "#{gitlab_issues_path}/#{id}", nil, {'PRIVATE-TOKEN': @service.data.private_token}
    issue = found_resource(response)
    issue if issue && issue['milestone'] && (issue['milestone']['id'] == milestone['id'])
  end

  def create(new_issue)
    prepare_request
    response = http_post gitlab_issues_path, new_issue.to_json, {'PRIVATE-TOKEN': @service.data.private_token}
    process_response(response, 201) do |issue|
      return issue
    end
  end

  def update(number, updated_issue)
    updated_issue[:labels] = updated_issue[:labels].join(',') if updated_issue.key?(:labels) && updated_issue[:labels].is_a?(Array)
    prepare_request
    response = http_put "#{gitlab_issues_path}/#{number}", updated_issue.to_json, {'PRIVATE-TOKEN': @service.data.private_token}
    process_response(response, 200) do |issue|
      return issue
    end
  end

private

  def gitlab_issues_path
    "#{ @service.server_url }/projects/#{get_project_id}/issues"
  end
end
