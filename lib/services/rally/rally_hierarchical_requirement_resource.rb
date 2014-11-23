class RallyHierarchicalRequirementResource < RallyResource

  def create_from_feature aha_feature
    body = { :HierarchicalRequierement => map_feature(aha_feature) }.to_json
    url = rally_secure_url "/hierarchicalrequirement/create"
    response = http_put url, body
    process_response response, 200, 201 do |document|
      hrequirement = document.CreateResult.Object
      api.create_integration_fields "features", aha_feature.id, @service.data.integration_id, { id: hrequirement.ObjectID, url: hrequirement._ref }
      create_from_requirements hrequirement, aha_feature.requirements
      create_attachments hrequirement, (aha_feature.attachments | aha_feature.description.attachments)
    end
  rescue AhaService::RemoteError => e
    logger.error("Failed create new user story from feature: #{e.message}")
  end

  def create_from_requirements parent, aha_requirements
    aha_requirements.each do |aha_requirement|
      create_from_requirement parent, aha_requirement
    end
  end

  def create_from_requirement parent, aha_requirement
    body = { :HierarchicalRequierement => map_requirement(parent, aha_requirement) }.to_json
    url = rally_secure_url "/hierarchicalrequirement/create"
    response = http_put url, body
    process_response response, 200, 201 do |document|
      hrequirement = document.CreateResult.Object
      api.create_integration_fields "requirements", aha_requirement.id, @service.data.integration_id, { id: hrequirement.ObjectID, url: hrequirement._ref }
      create_attachments hrequirement, (aha_requirement.attachments | aha_requirement.description.attachments)
    end
  rescue AhaService::RemoteError => e
    logger.error("Failed create new user story from requirement: #{e.message}")
  end

protected
  def map_feature aha_feature
    rally_release_id = aha_feature.release.integration_fields.find{|field| field.integration_id == @service.data.integration_id.to_s and field.name == "id"}.value
    {
      :Release => rally_release_id,
      :Description => aha_feature.description.body,
      :Name => aha_feature.name
    }
  end

  def map_requirement parent, aha_requirement
    {
      :Parent => parent.ObjectID,
      :Release => parent.Release,
      :Description => aha_requirement.description.body,
      :Name => aha_requirement.name
    }
  end

  def create_attachments parent, aha_attachments
    aha_attachments.each do |aha_attachment|
      rally_attachment_resource.create parent, aha_attachment
    end
  end

  def rally_attachment_resource
    @rally_attachment_resource ||= RallyAttachmentResource.new @service
  end
end
