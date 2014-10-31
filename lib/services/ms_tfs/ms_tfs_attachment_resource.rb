require 'open-uri'

class MSTFSAttachmentResource < MSTFSResource

  def create aha_attachment
    logger.info("Uploading attachment #{aha_attachment.file_name}")

    http.headers["Transfer-Encoding"] = "chunked"
    open(aha_attachment.download_url) do |downloaded_file|
      url = mstfs_url "wit/attachments?fileName=" + aha_attachment.file_name
      response = http_post url, downloaded_file
      if response.status == 201
        created_attachment = parsed_body response
        # TODO: Can attachments have integration fields?
        #api.create_integration_fields("attachments", aha_attachment.id, @service.data.integration_id, {id: created_attachment.id, url: created_attachment.url})
        return created_attachment
      end
      raise AhaService::RemoteError.new("Response code is " + response.status)
    end

  rescue AhaService::RemoteError => e
    logger.error("Failed to upload attachment : #{e.message}")
  ensure
    #http_reset
  end

end
