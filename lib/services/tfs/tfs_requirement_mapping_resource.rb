class TFSRequirementMappingResource < TFSResource

  def create_and_link project, parent, aha_requirement
    created_workitem = workitem_resource.create project, mapped_type, Hash[
      "System.Title" => aha_requirement.name || "",
      "System.Description" => aha_requirement.description.body || "",
      "System.AreaPath" => @service.data.area,
    ]
    workitem_resource.update created_workitem.id, [{
      :op => :add,
      :path => "/relations/-",
      :value => {
        :rel => "System.LinkTypes.Hierarchy-Reverse",
        :url => parent.url,
      }
    }]
    api.create_integration_fields("requirements", aha_requirement.reference_num, @service.data.integration_id, {id: created_workitem.id, url: created_workitem._links.html.href})
    return created_workitem
  end

  def create_or_update project, parent, aha_requirement
    integration_field = aha_requirement.integration_fields.find {|field| field.name == "id" and field.integration_id.to_i == @service.data.integration_id}
    if integration_field
      update integration_field.value, aha_requirement
    else
      create_and_link project, parent, aha_requirement
    end
  end

  def update workitem_id, aha_requirement
    workitem = workitem_resource.by_id workitem_id
    patch_set = []
    if workitem.fields["System.Title"] != aha_requirement.name then
      patch_set << {
        :op => :replace,
        :path => "/fields/System.Title",
        :value => aha_requirement.name
      }
    end
    if workitem.fields["System.Description"] != aha_requirement.description.body then
      patch_set << {
        :op => :replace,
        :path => "/fields/System.Description",
        :value => aha_requirement.description.body
      }
    end
    workitem_resource.update workitem_id, patch_set
  end

  def update_aha_requirement aha_requirement, workitem
      changes = {}
      if aha_requirement.name != workitem.fields["System.Title"]
        changes[:name] = workitem.fields["System.Title"]
      end
      if aha_requirement.description.body != workitem.fields["System.Description"]
        changes[:description] = workitem.fields["System.Description"]
      end
      new_status = tfs_to_aha_status workitem.fields["System.State"]
      if aha_requirement.workflow_status.id != new_status
        changes[:workflow_status] = new_status
      end
      if changes.length > 0
        api.put aha_requirement.resource, { :requirement => changes }
      end
  end

protected
  def workitem_resource
    @workitem_resource ||= TFSWorkItemResource.new @service
  end

  def mapped_type
    @service.data.requirement_mapping
  end
  
  def tfs_to_aha_status status
    @service.data.requirement_status_mapping[status]
  end
end
