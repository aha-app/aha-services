class RallyHierarchicalRequirementResource < RallyResource

  def create_from_feature aha_feature
    get_security_token
    body = { :HierarchicalRequierement => map_feature(aha_feature) }.to_json
    url = rally_secure_url "/hierarchicalrequirement/create"
    response = http_put url, body
    process_response response, 200, 201 do |document|
      hrequirement = document.CreateResult.Object
      pp hrequirement
      api.create_integration_fields "features", aha_feature.id, @service.data.integration_id, { id: hrequirement.ObjectID, url: hrequirement._ref }
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
end
