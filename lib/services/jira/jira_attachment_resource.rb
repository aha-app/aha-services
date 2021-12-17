require 'open-uri'
require "stringio"

class JiraAttachmentResource < JiraResource
  def all_for_issue(issue_id)
    prepare_request
    response = http_get "#{api_url}/issue/#{issue_id}?fields=attachment"
    process_response(response, 200) do |issue|
      return issue.fields.try(:attachment) || []
    end
  end

  def download(attachment)
    prepare_request
    http.headers['X-Atlassian-Token'] = 'nocheck'
    response = http_get attachment["content"]
    return StringIO.new(response.body)
  end

  def upload(attachment, issue_id)
    logger.info("Uploading attachment #{attachment.file_name}")

    return unless attachment.download_url

    URI.open(attachment.download_url) do |downloaded_file|
      # Reset Faraday and switch to multipart to do the file upload.
      http_reset
      http(:encoding => :multipart)
      http.headers['X-Atlassian-Token'] = 'nocheck'

      file = Faraday::UploadIO.new(downloaded_file, attachment.content_type, attachment.file_name)
      response = http_post "#{api_url}/issue/#{issue_id}/attachments", { file: file }
      process_response(response, 200)
    end

  rescue AhaService::RemoteError, Zlib::BufError => e
    logger.error("Unable to attach '#{attachment.file_name}', perhaps it is too large.")
  ensure
    http_reset
    prepare_request
  end
end
