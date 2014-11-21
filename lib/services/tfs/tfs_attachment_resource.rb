require 'open-uri'

class TFSAttachmentResource < TFSResource

  def create aha_attachment
    logger.info("Uploading attachment #{aha_attachment.file_name}")

    http.headers["Transfer-Encoding"] = "chunked"
    open(aha_attachment.download_url) do |downloaded_file|
      url = mstfs_url "wit/attachments?fileName=" + aha_attachment.file_name
      response = http_post url, downloaded_file
      process_response response, 201
    end

  rescue AhaService::RemoteError => e
    logger.error("Failed to upload attachment : #{e.message}")
  end

end
