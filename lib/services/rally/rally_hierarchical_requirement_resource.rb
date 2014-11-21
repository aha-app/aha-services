class RallyHierarchicalRequirementResource < RallyResource

  def create_from_feature aha_feature
    get_security_token
    body = { :HierarchicalRequierement => map_feature(aha_feature) }.to_json
    url = rally_secure_url "/hierarchicalrequirement/create"
    response = http_put url, body
    process_response response, 200, 201 do |document|
      hrequirement = document.CreateResult.Object
      api.create_integration_fields "features", aha_feature.id, @service.data.integration_id, { id: hrequirement.ObjectID, url: hrequirement._ref }
      create_from_requirements hrequirement, aha_feature.requirements
    end
  end

  def create_from_requirements parent, aha_requirements
    aha_requirements.each do |aha_requirement|
      create_from_requirement parent, aha_requirement
    end
  end

  def create_from_requirement parent, aha_requirement
    get_security_token
    body = { :HierarchicalRequierement => map_requirement(parent, aha_requirement) }
    pp body
    body = body.to_json
    url = rally_secure_url "/hierarchicalrequirement/create"
    response = http_put url, body
    process_response response, 200, 201 do |document|
      hrequirement = document.CreateResult.Object
      api.create_integration_fields "requirements", aha_requirement.id, @service.data.integration_id, { id: hrequirement.ObjectID, url: hrequirement._ref }
    end
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
end
