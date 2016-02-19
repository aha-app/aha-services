# This class deals with either PortfolioItems or UserStories
class RallyHierarchicalRequirementResource < RallyResource
  def object_path(id, element_name)
    if element_name == "UserStory"
      "/hierarchicalrequirement/#{id}"
    else
      "/portfolioitem/#{element_name.downcase}/#{id}"
    end
  end

  def get id, element_name
    url = rally_url(object_path(id, element_name))
    process_response http_get(url) do |document|
      if element_name == "UserStory"
        return document.HierarchicalRequirement
      else
        return document["Portfol"]
      end
    end
  end

  def portfolio_item_or_hr_path id, element_name
    if element_name == "UserStory"
      "/hierarchicalrequirement/#{id}"
    else
      "/portfolioitem/#{id}"
    end
  end

  def get_children id, element_name
    url = rally_url(portfolio_item_or_hr_path(id, element_name) + "/Children")
    process_response http_get(url) do |document|
      return document.QueryResult.Results
    end
  end

  def get_attachments id, element_name
    url = rally_url(portfolio_item_or_hr_path(id, element_name) + "/Attachments")
    process_response http_get(url) do |document|
      return document.QueryResult.Results
    end
  end

  def create_path element_name
    if element_name == "UserStory"
      "/hierarchicalrequirement/create"
    else
      "/portfolioitem/#{element_name.downcase}/create"
    end
  end

  def create hrequirement, element_name
    body = {}
    url = rally_secure_url(create_path(element_name))
    payload_key = element_name
    if element_name == "UserStory"
      payload_key = "HierarchicalRequierement"
    end
    body[payload_key] = hrequirement
    response = http_put url, body.to_json
    process_response response, 200, 201 do |document|
      hrequirement = document.CreateResult.Object
      yield hrequirement if block_given?
    end
  rescue AhaService::RemoteError => e
    logger.error("Failed create new #{element_name}: #{e.message}")
  end

  def update id, hrequirement, element_name
    body = {}
    url = rally_secure_url(object_path(id, element_name))
    payload_key = element_name
    if element_name == "UserStory"
      payload_key = "HierarchicalRequierement"
    end
    body[payload_key] = hrequirement
    response = http_post url, body.to_json
    process_response response, 200, 201 do |document|
      hrequirement = document.OperationResult.Object
      yield hrequirement if block_given?
      hrequirement
    end
  rescue AhaService::RemoteError => e
    logger.error("Failed to update user story #{id}: #{e.message}")
  end


  def human_url_for_feature(id)
    if @service.feature_element_name == "UserStory"
      "https://rally1.rallydev.com/#/detail/userstory/#{id}"
    else
      "https://rally1.rallydev.com/#/detail/portfolioitem/#{@service.feature_element_name.downcase}/#{id}"
    end
  end

  def human_url_for_requirement(id)
    if @service.requirement_element_name == "UserStory"
      "https://rally1.rallydev.com/#/detail/userstory/#{id}"
    else
      "https://rally1.rallydev.com/#/detail/portfolioitem/#{@service.requirement_element_name.downcase}/#{id}"
    end
  end

  def create_from_feature aha_feature
    release_id = map_to_objectid aha_feature.release
    create map_feature(aha_feature), @service.feature_element_name do |hrequirement|
      api.create_integration_fields "features", aha_feature.id, @service.data.integration_id, { id: hrequirement.ObjectID, formatted_id: hrequirement.FormattedID, url: human_url_for_feature(hrequirement.ObjectID) }
      aha_feature.requirements.each{|requirement| create_from_requirement hrequirement.ObjectID, release_id, requirement }
      create_attachments hrequirement, (aha_feature.attachments | aha_feature.description.attachments)
    end
  end

  def create_from_requirement parent_id, release_id, aha_requirement
    mapped_requirement = map_requirement(parent_id, release_id, aha_requirement)
    @service.logger.debug "Mapped requirement for create: #{mapped_requirement.inspect}"
    create(mapped_requirement, @service.requirement_element_name) do |hrequirement|
      api.create_integration_fields "requirements", aha_requirement.id, @service.data.integration_id, { id: hrequirement.ObjectID, formatted_id: hrequirement.FormattedID, url: human_url_for_requirement(hrequirement.ObjectID) }
      create_attachments hrequirement, (aha_requirement.attachments | aha_requirement.description.attachments)
    end
  end

  def update_from_feature aha_feature
    id = map_to_objectid aha_feature
    release_id = map_to_objectid aha_feature.release
    update id, map_feature(aha_feature), @service.feature_element_name do |hrequirement|
      @service.logger.debug "Successful update for feature, object: #{hrequirement.to_json.inspect}"
      rally_attachment_resource.sync_attachments(
        hrequirement,
        (aha_feature.attachments | aha_feature.description.attachments),
        get_attachments(id, @service.feature_element_name)
      )
    end

    sync_requirements id, release_id, aha_feature.requirements
  end

  def update_from_requirement parent_id, release_id, aha_requirement
    id = map_to_objectid aha_requirement
    requirement_payload = map_requirement(parent_id, release_id, aha_requirement)

    @service.logger.debug "Mapped requirement for update: #{requirement_payload.inspect}"
    update id, requirement_payload, @service.requirement_element_name do |hrequirement|
      @service.logger.debug "Successful update for requirement, object: #{hrequirement.to_json.inspect}"
      rally_attachment_resource.sync_attachments(
        hrequirement,
        (aha_requirement.attachments | aha_requirement.description.attachments),
        get_attachments(id, @service.requirement_element_name)
      )
    end
  end

  def sync_requirements parent_id, release_id, aha_requirements
    old_requirements, new_requirements = aha_requirements.partition{|requirement| map_to_objectid(requirement) }

    new_requirements.each{|requirement| create_from_requirement(parent_id, release_id, requirement) }
    old_requirements.each{|requirement| update_from_requirement(parent_id, release_id, requirement) }
  end

protected
  def map_feature aha_feature
    rally_release_id = map_to_objectid aha_feature.release
    attributes = {
      :Description => aha_feature.description.body,
      :Name => aha_feature.name,
      :Project => @service.data.project
    }
    include_release_if_exists(aha_feature, attributes, rally_release_id)
    attributes
  end

  def map_requirement parent_id, release_id, aha_requirement
    mapping = {
      :Description => aha_requirement.description.body,
      :Name => aha_requirement.name,
      :Project => @service.data.project
    }

    # The only time we should include the PortfolioItem field is when we are mapping across the hierarchicalRequirement boundary.
    if (@service.feature_element_name != "UserStory" && @service.requirement_element_name == "UserStory")
      mapping[:PortfolioItem] = parent_id.to_i
    else
      mapping[:Parent] = parent_id.to_i
    end
    include_release_if_exists(aha_requirement, mapping, release_id)
    mapping
  end

  def create_attachments parent, aha_attachments
    aha_attachments.each do |aha_attachment|
      rally_attachment_resource.create parent, aha_attachment
    end
  end

  # Rally will fail the API call if we attempt to assign this to a release that does not exist.
  # Rally will also fail the API call if we attempt to set Release for a feature that is not a leaf node.
  def include_release_if_exists aha_model, attributes, release_id
    return if (aha_model.requirements.try(:length) || 0) > 0 # do not send if we know for a fact this is not a leaf
    children_count = get_children(map_to_objectid(aha_model)).length rescue 0
    return if children_count > 0 # do not send if rally has children for this resource
    release_exists = release_id && rally_release_resource.by_id(release_id) rescue false
    return unless release_exists # do not send if rally does not know the release (This means the user deleted it)
    attributes[:Release] = release_id
  end

  def rally_release_resource
    @rally_release_resource ||= RallyReleaseResource.new @service
  end

  def rally_attachment_resource
    @rally_attachment_resource ||= RallyAttachmentResource.new @service
  end
end
