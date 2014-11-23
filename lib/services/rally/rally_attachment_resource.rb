class RallyAttachmentResource < RallyResource
  def create parent, aha_attachment
    attachmentcontent = rally_attachment_content_resource.create aha_attachment.download_url
    url = rally_secure_url "/attachment/create"
    body = { :Attachment => {
      :Artifact => parent.ObjectID,
      :Content => attachmentcontent.ObjectID,
      :ContentType => aha_attachment.content_type,
      :Name => aha_attachment.file_name,
      :Size => aha_attachment.file_size
    }}.to_json
    response = http_put url, body
    process_response response do |document|
      return document.CreateResult.Object
    end
  rescue AhaService::RemoteError => e
    logger.error("Failed create new attachment: #{e.message}")
  end

protected
  def rally_attachment_content_resource
    @rally_attachment_content_resource ||= RallyAttachmentContentResource.new @service
  end
end
