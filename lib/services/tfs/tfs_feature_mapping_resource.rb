class TFSFeatureMappingResource < TFSResource

  def create project, aha_feature
    # create new workitem in TFS
    created_workitem = workitem_resource.create project, mapped_type, Hash[
      "System.Title" => aha_feature.name || "",
      "System.Description" => aha_feature.description.body || "",
      "System.AreaPath" => @service.data.area,
    ]
    # add integration field to workitem in aha
    api.create_integration_fields("features", aha_feature.reference_num, @service.data.integration_id, {id: created_workitem.id, url: created_workitem._links.html.href})
    # create a workitem in TFS for each requirement
    create_and_link_requirements project, created_workitem, aha_feature.requirements
    # upload all attachments to TFS and link them to the workitem
    create_attachments created_workitem, (aha_feature.attachments | aha_feature.description.attachments)
    return created_workitem
  end

  def update workitem_id, aha_feature
    workitem = workitem_resource.by_id workitem_id
    # determine changes
    patch_set = []
    if workitem.fields["System.Title"] != aha_feature.name then
      patch_set << {
        :op => :replace,
        :path => "/fields/System.Title",
        :value => aha_feature.name
      }
    end
    if workitem.fields["System.Description"] != aha_feature.description.body then
      patch_set << {
        :op => :replace,
        :path => "/fields/System.Description",
        :value => aha_feature.description.body
      }
    end
    # update the feature
    workitem_resource.update workitem.id, patch_set
    # update associated requirements
    aha_feature.requirements.each do |requirement|
      requirement_mapping_resource.create_or_update @service.data.project, workitem, requirement
    end
    # add new attachments
    create_attachments workitem, (aha_feature.attachments | aha_feature.description.attachments)
  end

  def update_aha_feature aha_feature, workitem
      changes = {}
      if aha_feature.name != workitem.fields["System.Title"]
        changes[:name] = workitem.fields["System.Title"]
      end
      if aha_feature.description.body != workitem.fields["System.Description"]
        changes[:description] = workitem.fields["System.Description"]
      end
      if changes.length > 0
        api.put aha_feature.resource, { :feature => changes }
      end
  end

protected
  def create_attachments workitem, aha_attachments
    existing_files = workitem.relations.select{|relation| relation.rel == "AttachedFile"}.map{|relation| relation.attributes.name} rescue []
    aha_attachments.each do |aha_attachment|
      next if existing_files.include?(aha_attachment.file_name)
      new_attachment = attachment_resource.create aha_attachment
      workitem_resource.add_attachment workitem, new_attachment, aha_attachment.file_size
    end
  rescue AhaService::RemoteError => e
    logger.error e.message
  end

  def create_and_link_requirements project, workitem, requirements
    requirements.each do |requirement|
      requirement_mapping_resource.create_and_link project, workitem, requirement
    end
  rescue AhaService::RemoteError => e
    logger.error e.message
  end

  def mapped_type
    @serivce.data.feature_mapping
  end

  def attachment_resource
    @attachment_resource ||= TFSAttachmentResource.new(@service)
  end

  def workitem_resource
    @workitem_resource ||= TFSWorkItemResource.new(@service)
  end

  def requirement_mapping_resource
    @requirement_mapping_resource ||= TFSRequirementMappingResource.new @service
  end
end

