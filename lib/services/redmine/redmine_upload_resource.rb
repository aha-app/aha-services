class RedmineUploadResource < RedmineResource
  
  def all_for_issue(issue_id)
    prepare_request
    response = http_get "#{@service.data.redmine_url}/issues/#{issue_id}.json?include=attachments"
    process_response(response, 200) do |response|
      return response.issue.attachments
    end
  end
  
  def upload_attachment attachment
    open attachment.download_url do |downloaded_file|
      # Reset Faraday and switch to multipart to do the file upload.
      http_reset
      http encoding: :multipart
      http.headers['Content-Type'] = 'application/octet-stream'
      auth_header
      
      file = Faraday::UploadIO.new downloaded_file, attachment.content_type, attachment.file_name
      response = http_post redmine_upload_path, file.read
      process_response response, 201 do |body|
        return body.upload.token
      end
    end

    rescue AhaService::RemoteError => e
      logger.error("Failed to upload attachment\nNAME: #{attachment.name}\n#{e.message}")
    ensure
      http_reset
  end

private

  def redmine_upload_path
    "#{@service.data.redmine_url}/uploads.json"
  end

end