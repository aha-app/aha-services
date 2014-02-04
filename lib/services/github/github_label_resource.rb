class GithubLabelResource < GithubResource
  def update(issue_number, updated_labels)
    updated_labels ||= []
    prepare_request
    response = http_put github_labels_path(issue_number), updated_labels.to_json
    process_response(response, 200) do |labels|
      return labels
    end
  end

private

  def github_labels_path(issue_number)
    "#{API_URL}/repos/#{@service.data.username}/#{@service.data.repo}/issues/#{issue_number}/labels"
  end
end
