class MSTFSFeatureResource < MSTFSResource

  def create project, aha_feature
    # create new feature in TFS
    created_feature = workitem_resource.create project, "Feature", Hash[
      "System.Title" => aha_feature.name,
      "System.Description" => aha_feature.description.body,
    ]
    # add integration field to feature in aha
    api.create_integration_fields("features", aha_feature.reference_num, @service.data.integration_id, {id: created_feature.id, url: created_feature.url})
    # create a workitem in TFS for each requirement
    create_and_link_requirements project, created_feature, aha_feature.requirements
    # upload all attachments to TFS and link them to the feature
    create_attachments created_feature, (aha_feature.attachments | aha_feature.description.attachments)
    return created_feature
  end

  def update tfs_feature_id, aha_feature
    tfs_feature = workitem_resource.by_id tfs_feature_id
    patch_set = []
    if tfs_feature.fields["System.Title"] != aha_feature.name then
      patch_set << {
        :op => :replace,
        :path => "/fields/System.Title",
        :value => aha_feature.name
      }
    end
    if tfs_feature.fields["System.Description"] != aha_feature.description.body then
      patch_set << {
        :op => :replace,
        :path => "/fields/System.Description",
        :value => description
      }
    end
    # TODO update attachments and requirements
    workitem_resource.update tfs_feature.id, patch_set
  end

  def update_aha_feature aha_feature, tfs_feature
      changes = {}
      if aha_feature.name != tfs_feature.fields["System.Title"]
        changes[:name] = tfs_feature.fields["System.Title"]
      end
      if aha_feature.description.body != tfs_feature.fields["System.Description"]
        changes[:description] = tfs_feature.fields["System.Description"]
      end
      if changes.length > 0
        api.put feature.resource, { :feature => changes }
      end
  end

protected
  def create_attachments tfs_feature, aha_attachments
    aha_attachments.each do |aha_attachment|
      new_attachment = attachment_resource.create aha_attachment
      workitem_resource.add_attachment tfs_feature, new_attachment
    end
  end

  def create_and_link_requirements project, tfs_feature, requirements
    requirements.each do |requirement|
      requirement_mapping_resource.create_and_link project, tfs_feature, requirement
    end
  end

  def attachment_resource
    @attachment_resource ||= MSTFSAttachmentResource.new(@service)
  end

  def workitem_resource
    @workitem_resource ||= MSTFSWorkItemResource.new(@service)
  end

  def requirement_mapping_resource
    @requirement_mapping_resource ||= MSTFSRequirementMappingResource.new @service
  end
end

