require 'open-uri'

class PivotalTrackerAttachmentResource < PivotalTrackerProjectDependentResource
  def all_for_story(story_id)
    all_attachments("stories", story_id)
  end

  def all_for_epic(epic_id)
    all_attachments("epics", epic_id)
  end

  def upload(attachments)
    attachments.collect do |attachment|
      upload_single_attachment(attachment)
    end
  end

  def update(resource, pivotal_tracker_attachments)
    aha_attachments = resource.attachments.dup | resource.description.attachments.dup
    upload(new_aha_attachments(aha_attachments, pivotal_tracker_attachments))
  end

private

  def all_attachments(resource_name, resource_id)
    prepare_request
    response = http_get "#{api_url}/projects/#{project_id}/#{resource_name}/#{resource_id}/comments?fields=file_attachments"
    process_response(response, 200) do |comments|
      return comments.collect {|c| c.file_attachments }.flatten
    end
  end

  def new_aha_attachments(aha_attachments, pivotal_tracker_attachments)
    pivotal_tracker_attachments.each do |pivotal_attachment|
      # Remove any attachments that match.
      aha_attachments.reject! do |aha_attachment|
        attachments_match(aha_attachment, pivotal_attachment)
      end
    end

    aha_attachments
  end

  def attachments_match(aha_attachment, pivotal_attachment)
    logger.debug("MATCHING: #{aha_attachment.file_name} #{pivotal_attachment.filename} #{aha_attachment.file_size.to_i} #{pivotal_attachment['size'].to_i}")
    aha_attachment.file_name == pivotal_attachment.filename
  end

  def upload_single_attachment(attachment)
    logger.info("Uploading attachment #{attachment.file_name}")

    return unless attachment.download_url

    URI.open(attachment.download_url) do |downloaded_file|
      # Reset Faraday and switch to multipart to do the file upload.
      http_reset
      http(:encoding => :multipart)
      http.headers['X-TrackerToken'] = @service.data.api_token

      file = Faraday::UploadIO.new(downloaded_file, attachment.content_type, attachment.file_name)
      response = http_post("#{api_url}/projects/#{project_id}/uploads", {:file => file})
      process_response(response, 200) do |file_attachment|
        return file_attachment
      end
    end

  rescue AhaService::RemoteError => e
    logger.error("Failed to upload attachment to #{project_id}: #{e.message}")
  ensure
    http_reset
  end
end
