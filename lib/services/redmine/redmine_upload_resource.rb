class RedmineUploadResource < RedmineResource
  def upload_attachment attachment
    open attachment.download_url do |downloaded_file|
      # Reset Faraday and switch to multipart to do the file upload.
      http_reset
      http(:encoding => :multipart)

      file = Faraday::UploadIO.new downloaded_file, attachment.content_type, attachment.file_name
      response = http_post redmine_upload_path, file: file
      process_response response, 201 do |body|
        return body.upload.token
      end
    end

    rescue AhaService::RemoteError => e
      logger.error("Failed to upload attachment\nID #{attachment.id}\nNAME: #{attachment.name}\n\t: #{e.message}")
    ensure
      http_reset
  end

private

  def redmine_upload_path
    "#{@service.data.redmine_url}/uploads.json"
  end

end