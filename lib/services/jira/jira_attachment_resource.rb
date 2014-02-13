require 'open-uri'

class JiraAttachmentResource < JiraResource
  def all_for_issue(issue_id)
    prepare_request
    response = http_get "#{api_url}/issue/#{issue_id}?fields=attachment"
    process_response(response, 200) do |issue|
      return issue['fields']['attachment']
    end
  end

  def upload(attachment, issue_id)
    open(attachment.download_url) do |downloaded_file|
      # Reset Faraday and switch to multipart to do the file upload.
      http_reset
      http(:encoding => :multipart)
      http.headers['X-Atlassian-Token'] = 'nocheck'
      auth_header

      file = Faraday::UploadIO.new(downloaded_file, attachment.content_type, attachment.file_name)
      response = http_post "#{api_url}/issue/#{issue_id}/attachments", { file: file }
      process_response(response, 200)
    end

  rescue AhaService::RemoteError => e
    logger.error("Failed to upload attachment to #{issue_key}: #{e.message}")
  ensure
    http_reset
    prepare_request
  end
end
