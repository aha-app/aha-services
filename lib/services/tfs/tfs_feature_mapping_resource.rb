class TFSFeatureMappingResource < TFSResource

  def create project, aha_feature
    body = {
      "System.Title" => aha_feature.name || "Untitled feature",
      "System.Description" => description_or_default(aha_feature.description.body),
      "System.AreaPath" => @service.data.area
    }
    add_default_fields(body)
    
    # create new workitem in TFS
    created_workitem = workitem_resource.create project, mapped_type, body
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
      requirement_mapping_resource.create_or_update(@service.data.project, workitem, requirement)
    end
    # Add new attachments
    create_attachments(workitem, (aha_feature.attachments | aha_feature.description.attachments))
  end

  def update_aha_feature aha_feature, workitem
    changes = {}
    if aha_feature.name != workitem.fields["System.Title"]
      changes[:name] = workitem.fields["System.Title"]
    end
    if aha_feature.description.body != workitem.fields["System.Description"]
      changes[:description] = workitem.fields["System.Description"]
    end
    new_status = tfs_to_aha_status workitem.fields["System.State"]
    if aha_feature.workflow_status.id != new_status
      changes[:workflow_status] = new_status
    end
    if changes.length > 0
      api.put aha_feature.resource, { :feature => changes }
    end
  end

protected
  def add_default_fields(body)
    (@service.data.feature_default_fields || []).each do |field_mapping|
      next unless field_mapping.is_a? Hashie::Mash
      
      body[field_mapping.field] = field_mapping.value
    end
  end

  def create_and_link_requirements project, workitem, requirements
    requirements.each do |requirement|
      requirement_mapping_resource.create_and_link project, workitem, requirement
    end
  rescue AhaService::RemoteError => e
    logger.error e.message
  end

  def mapped_type
    @service.data.feature_mapping
  end

  def tfs_to_aha_status status
    @service.data.feature_status_mapping[status]
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

