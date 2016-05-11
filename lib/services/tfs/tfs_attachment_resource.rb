require 'open-uri'

class TFSAttachmentResource < TFSResource

  def create aha_attachment
    logger.info("Uploading attachment #{aha_attachment.file_name}")
    return unless aha_attachment.download_url

    http.headers["Transfer-Encoding"] = "chunked"
    open(aha_attachment.download_url) do |downloaded_file|
      url = mstfs_url("wit/attachments?fileName=" + URI.escape(aha_attachment.file_name))
      response = http_post url, downloaded_file.read, "Content-Length" => downloaded_file.length.to_s
      process_response response, 201
    end

  rescue AhaService::RemoteError => e
    logger.error("Failed to upload attachment : #{e.message}")
    return nil
  end

end
