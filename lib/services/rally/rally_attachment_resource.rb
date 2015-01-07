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

  def delete attachment
    rally_attachment_content_resource.delete_by_url attachment.Content._ref rescue nil
    url = rally_secure_url "/attachment/#{attachment.ObjectID}"
    process_response http_delete(url), 200, 201
  rescue AhaService::RemoteError => e
    logger.error "Could not fully delete attachment or attachment content: #{e.message}"
  end

  def sync_attachments hrequirement, aha_attachments
    rally_attachments = rally_hierarchical_requirement_resource.get_attachments hrequirement.ObjectID
    # determine attachments not yet created in Rally
    new_attachments = aha_attachments.select{|attachment| not rally_attachments.map{|a| a.Name}.include?(attachment.file_name) }
    # determine attachments which allready are in Rally but have changed in Aha!
    changed_attachments = aha_attachments.select do |a_a|
      r_a = rally_attachments.find{|a| a.Name == a_a.file_name}
      r_a && r_a.Size.to_i != a_a.file_size.to_i
    end
    # delete all attachments that have changed
    changed_attachments.each do |aha_attachment|
      rally_attachment = rally_attachments.find{|a| a.Name == aha_attachment.file_name}
      delete rally_attachment
    end
    # create all new and changed attachments
    (new_attachments | changed_attachments).each do |aha_attachment|
      create hrequirement, aha_attachment
    end
  end

protected
  def rally_attachment_content_resource
    @rally_attachment_content_resource ||= RallyAttachmentContentResource.new @service
  end

  def rally_hierarchical_requirement_resource
    @rally_hierarchical_requirement_resource ||= RallyHierarchicalRequirementResource.new @service
  end
end
