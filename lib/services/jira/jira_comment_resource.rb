class JiraCommentResource < JiraResource

  def create(issue_id, new_comment)
    prepare_request
    response = http_post "#{api_url}/issue/#{issue_id}/comment", new_comment.to_json
    process_response(response, 201) do |comment|
      return comment
    end
  end
  
end
