require 'open-uri'

class PivotalTrackerAttachmentResource < PivotalTrackerResource
  def all_for_story(project_id, story_id)
    prepare_request
    response = http_get "#{api_url}/projects/#{project_id}/stories/#{story_id}/comments?fields=file_attachments"
    process_response(response, 200) do |comments|
      return comments.collect {|c| c.file_attachments }.flatten
    end
  end

  def upload(attachment)
    logger.info("Uploading attachment #{attachment.file_name}")
    
    open(attachment.download_url) do |downloaded_file|
      # Reset Faraday and switch to multipart to do the file upload.
      http_reset 
      http(:encoding => :multipart)
      http.headers['X-TrackerToken'] = @service.data.api_token
      
      file = Faraday::UploadIO.new(downloaded_file, attachment.content_type, attachment.file_name)
      response = http_post("#{api_url}/projects/#{@service.data.project}/uploads", {:file => file})
      process_response(response, 200) do |file_attachment|
        return file_attachment
      end
    end
        
  rescue AhaService::RemoteError => e
    logger.error("Failed to upload attachment to #{@service.data.project}: #{e.message}")
  ensure
    http_reset
  end
end
