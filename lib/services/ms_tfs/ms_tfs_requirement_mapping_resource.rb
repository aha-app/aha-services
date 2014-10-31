class MSTFSRequirementMappingResource < MSTFSResource

  def create_and_link project, tfs_feature, aha_requirement
    created_workitem = workitem_resource.create project, mapped_type, Hash[
      "System.Title" => aha_requirement.name,
      "System.Description" => aha_requirement.description.body,
    ], [
      {
        :rel => "System.LinkTypes.Hierarchy-Forward",
        :url => tfs_feature.url
      }
    ]
    api.create_integration_fields("requirements", aha_requirement.reference_num, @service.data.integration_id, {id: created_workitem.id, url: created_workitem.url})
    return created_workitem
  end

protected
  def workitem_resource
    @workitem_resource ||= MSTFSWorkItemResource.new @service
  end

  def mapped_type
    @service.data.requirement_mapping
  end
end
