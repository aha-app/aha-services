class TrelloAttachmentResource < TrelloResource
  def all_for_card(card_id)
    prepare_request
    response = http_get trello_url("cards/#{card_id}/attachments")
    found_resource(response)
  end

  def upload(attachment, card_id)
    logger.info("Uploading attachment #{attachment.file_name}")

    return unless attachment.download_url

    open(attachment.download_url) do |downloaded_file|
      # Reset Faraday and switch to multipart to do the file upload.
      http_reset
      http(:encoding => :multipart)

      file = Faraday::UploadIO.new(downloaded_file, attachment.content_type, attachment.file_name)
      response = http_post trello_url("cards/#{card_id}/attachments"), { file: file }
    end

  rescue AhaService::RemoteError => e
    logger.error("Failed to upload attachment to #{card_id}: #{e.message}")
  ensure
    http_reset
    prepare_request
  end

end
