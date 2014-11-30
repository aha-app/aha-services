class RallyHierarchicalRequirementResource < RallyResource

  def get id
    url = rally_url "/hierarchicalrequirement/#{id}"
    process_response http_get(url) do |document|
      return document.HierarchicalRequirement
    end
  end

  def get_children id
    url = rally_url "/hierarchicalrequirement/#{id}/Children"
    process_response http_get(url) do |document|
      return document.QueryResult.Results
    end
  end

  def get_attachments id
    url = rally_url "/hierarchicalrequirement/#{id}/Attachments"
    process_response http_get(url) do |document|
      return document.QueryResult.Results
    end
  end

  def create hrequirement
    body = { :HierarchicalRequierement => hrequirement }.to_json
    url = rally_secure_url "/hierarchicalrequirement/create"
    response = http_put url, body
    process_response response, 200, 201 do |document|
      hrequirement = document.CreateResult.Object
      yield hrequirement if block_given?
    end
  rescue AhaService::RemoteError => e
    logger.error("Failed create new user story: #{e.message}")
  end

  def create_from_feature aha_feature
    create map_feature(aha_feature) do |hrequirement|
      api.create_integration_fields "features", aha_feature.id, @service.data.integration_id, { id: hrequirement.ObjectID, url: hrequirement._ref }
      aha_feature.requirements.each{|requirement| create_from_requirement hrequirement, requirement }
      create_attachments hrequirement, (aha_feature.attachments | aha_feature.description.attachments)
    end
  end

  def create_from_requirement parent, aha_requirement
    create map_requirement(parent, aha_requirement) do |hrequirement|
      api.create_integration_fields "requirements", aha_requirement.id, @service.data.integration_id, { id: hrequirement.ObjectID, url: hrequirement._ref }
      create_attachments hrequirement, (aha_requirement.attachments | aha_requirement.description.attachments)
    end
  end

  def update id, hrequirement
    body = { :HierarchicalRequierement => hrequirement }.to_json
    url = rally_secure_url "/hierarchicalrequirement/#{id}"
    response = http_post url, body
    process_response response, 200, 201 do |document|
      hrequirement = document.OperationResult.Object
      yield hrequirement if block_given?
      hrequirement
    end
  rescue AhaService::RemoteError => e
    logger.error("Failed to update user story #{id}: #{e.message}")
  end

  def update_from_feature aha_feature
    id = map_to_objectid aha_feature
    current = get id
    sync_requirements current, aha_feature.requirements
    update id, map_feature(aha_feature) do |hrequirement|
      rally_attachment_resource.sync_attachments hrequirement, (aha_feature.attachments | aha_feature.description.attachments)
    end
  end

  def update_from_requirement parent, aha_requirement
    id = map_to_objectid aha_requirement
    update id, map_requirement(parent, aha_requirement) do |hrequirement|
      rally_attachment_resource.sync_attachments hrequirement, (aha_requirement.attachments | aha_requirement.description.attachments)
    end
  end

  def sync_requirements hrequirement, aha_requirements
    # get current children of the user story
    # we do this first so that they do not contain ObjectIDs from children we create in the next step
    childIDs = get_children(hrequirement.ObjectID).map{|child| child.ObjectID }
    # create user stories which do not yet exist
    new_requirements = aha_requirements.select{|requirement| map_to_objectid(requirement).nil? }
    new_requirements.each{|requirement| create_from_requirement hrequirement, requirement}
    # delete user stories which have been deleted in Aha!
    existingIDs = (aha_requirements - new_requirements).map{|requirement| map_to_objectid(requirement)}
    (childIDs - existingIDs).each{|id| delete(id) }
    # update user stories from requirements which are neither new nor deleted
    (aha_requirements - new_requirements).each{|requirement| update_from_requirement(hrequirement, requirement) }
  end

  def delete id
    url = rally_secure_url "/hierarchicalrequirement/#{id}"
    response = http_delete url
    process_response response, 200, 201
  rescue AhaService::RemoteError => e
    logger.error("Unable to delete user storie with id #{id}: #{e.message}")
  end

protected
  def map_feature aha_feature
    rally_release_id = map_to_objectid aha_feature.release
    attributes = {
      :Description => aha_feature.description.body,
      :Name => aha_feature.name
    }
    # Only child leafs belong to a release
    # If this user story will have children, it's not a leaf and will not belong to a release
    attributes[:Release] = rally_release_id unless aha_feature.requirements.length > 0
    attributes
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
