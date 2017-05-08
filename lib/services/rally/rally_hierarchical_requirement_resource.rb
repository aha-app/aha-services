# This class deals with either PortfolioItems or UserStories
class RallyHierarchicalRequirementResource < RallyResource
  def object_path(id, element_name)
    if element_name == "UserStory"
      "/hierarchicalrequirement/#{id}"
    else
      "/portfolioitem/#{id}"
    end
  end

  def get(id, element_name)
    url = rally_url_without_workspace(object_path(id, element_name))
    process_response http_get(url) do |document|
      if element_name == "UserStory"
        return document.HierarchicalRequirement
      else
        return document[element_name]
      end
    end
  end

  def get_children(id, element_name)
    url = rally_url_without_workspace(object_path(id, element_name) + "/Children")
    process_response http_get(url) do |document|
      return document.QueryResult.Results
    end
  end

  def get_attachments(id, element_name)
    url = rally_url_without_workspace(object_path(id, element_name) + "/Attachments")
    process_response http_get(url) do |document|
      return document.QueryResult.Results
    end
  end

  def create_path(element_name)
    if element_name == "UserStory"
      "/hierarchicalrequirement/create"
    else
      "/portfolioitem/#{element_name.downcase}/create"
    end
  end

  # Ensure that we pass in the workspace parameter on create, so that
  # we are routed to the correct API endpoint
  def add_workspace_param_to_url url
    url = URI.parse(url)
    params = Rack::Utils.parse_nested_query(url.query)
    params["workspace"] = rally_workspace_url
    url.query = params.to_query
    url.to_s
  end

  def create(hrequirement, element_name)
    body = {}
    url = add_workspace_param_to_url(rally_secure_url_without_workspace(create_path(element_name)))
    payload_key = element_name
    if element_name == "UserStory"
      payload_key = "HierarchicalRequirement"
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

  def update(id, hrequirement, element_name, query_params = "")
    body = {}
    url = add_workspace_param_to_url(rally_secure_url_without_workspace(object_path(id, element_name)+query_params))
    payload_key = element_name
    if element_name == "UserStory"
      payload_key = "HierarchicalRequirement"
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
      "https://rally1.rallydev.com/#/#{@service.data.project}d/detail/userstory/#{id}"
    else
      "https://rally1.rallydev.com/#/#{@service.data.project}d/detail/portfolioitem/#{@service.feature_element_name.downcase}/#{id}"
    end
  end

  def human_url_for_requirement(id)
    if @service.requirement_element_name == "UserStory"
      "https://rally1.rallydev.com/#/#{@service.data.project}d/detail/userstory/#{id}"
    else
      "https://rally1.rallydev.com/#/#{@service.data.project}d/detail/portfolioitem/#{@service.requirement_element_name.downcase}/#{id}"
    end
  end

  def create_from_feature(aha_feature)
    create map_feature(aha_feature), @service.feature_element_name do |hrequirement|
      api.create_integration_fields "features", aha_feature.id, @service.data.integration_id, id: hrequirement.ObjectID, formatted_id: hrequirement.FormattedID, url: human_url_for_feature(hrequirement.ObjectID)
      create_attachments hrequirement, (aha_feature.attachments | aha_feature.description.attachments)

      # Ensure that rank is set
      patched_feature = aha_feature
      patched_feature.rally_object_id = hrequirement.ObjectID
      update_from_feature patched_feature
    end
  end

  def create_from_requirement(parent_id, release_id, aha_requirement)
    mapped_requirement = map_requirement(parent_id, release_id, aha_requirement)
    @service.logger.debug "Mapped requirement for create: #{mapped_requirement.inspect}"
    create(mapped_requirement, @service.requirement_element_name) do |hrequirement|
      api.create_integration_fields "requirements", aha_requirement.id, @service.data.integration_id, id: hrequirement.ObjectID, formatted_id: hrequirement.FormattedID, url: human_url_for_requirement(hrequirement.ObjectID)
      create_attachments hrequirement, (aha_requirement.attachments | aha_requirement.description.attachments)
    end
  end

  def update_from_feature(aha_feature)
    id = map_to_objectid(aha_feature) || aha_feature.rally_object_id
    release_id = map_to_objectid aha_feature.release
    query_params = maybe_set_rank_for_feature aha_feature
    update id, map_feature(aha_feature), @service.feature_element_name, query_params do |hrequirement|
      @service.logger.debug "Successful update for feature, object: #{hrequirement.to_json.inspect}"
      rally_attachment_resource.sync_attachments(
        hrequirement,
        (aha_feature.attachments | aha_feature.description.attachments),
        get_attachments(id, @service.feature_element_name)
      )
    end

    sync_requirements id, release_id, aha_feature.requirements
  end

  def update_from_requirement(parent_id, release_id, aha_requirement)
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

  def sync_requirements(parent_id, release_id, aha_requirements)
    old_requirements, new_requirements = aha_requirements.partition { |requirement| map_to_objectid(requirement) }

    new_requirements.each { |requirement| create_from_requirement(parent_id, release_id, requirement) }
    old_requirements.each { |requirement| update_from_requirement(parent_id, release_id, requirement) }
  end

  protected

  def map_feature(aha_feature)
    rally_release_id = map_to_objectid aha_feature.release
    attributes = {
      Description: aha_feature.description.body,
      Name: aha_feature.name,
      Project: @service.data.project
    }
    attributes = merge_default_fields(@service.data.feature_default_fields, attributes)

    if @service.feature_element_name != "UserStory"
      attributes[:PlannedStartDate] = aha_feature.start_date
      attributes[:PlannedEndDate] = aha_feature.due_date
    end

    maybe_add_workspace_to_object(attributes)
    maybe_add_owner_to_object(attributes, aha_feature)
    maybe_add_tags_to_object(attributes, aha_feature)

    include_release_if_exists(aha_feature, attributes, rally_release_id)
    attributes
  end

  def maybe_set_rank_for_feature(aha_feature)
    # Call back into Aha! to find another feature to rank relative to.
    adjacent_info = api.adjacent_integration_fields(
      reference_num_to_resource_type(aha_feature.reference_num),
      aha_feature.id,
      @service.data.integration_id).first


    return "" if !adjacent_info

    adjacent_feature_id = get_integration_field(adjacent_info.integration_fields, 'id')

    query_addition = if adjacent_info.direction == "before"
      "?rankBelow=/slm/webservice/v2.0/#{object_path(adjacent_feature_id, @service.feature_element_name)}"
    elsif adjacent_info.direction == "after"
      "?rankAbove=/slm/webservice/v2.0/#{object_path(adjacent_feature_id, @service.feature_element_name)}"
    else
      ""
    end
    query_addition
  end

  def maybe_add_owner_to_object(attributes, aha_object)
    if aha_object.assigned_to_user.try(:email) && user_id = rally_user_resource.user_id_for_email(aha_object.assigned_to_user.email)
      attributes[:Owner] = user_id
    elsif aha_object.created_by_user.try(:email) && user_id = rally_user_resource.user_id_for_email(aha_object.created_by_user.email)
      attributes[:Owner] = user_id
    end
  end

  def map_requirement(parent_id, release_id, aha_requirement)
    attributes = {
      Description: aha_requirement.description.body,
      Name: aha_requirement.name,
      Project: @service.data.project
    }
    attributes = merge_default_fields(@service.data.requirement_default_fields, attributes)

    maybe_add_workspace_to_object(attributes)
    maybe_add_owner_to_object(attributes, aha_requirement)
    maybe_add_tags_to_object(attributes, aha_requirement)

    # The only time we should include the PortfolioItem field is when we are mapping across the hierarchicalRequirement boundary.
    if @service.feature_element_name != "UserStory" && @service.requirement_element_name == "UserStory"
      attributes[:PortfolioItem] = parent_id.to_i
    else
      attributes[:Parent] = parent_id.to_i
    end
    include_release_if_exists(aha_requirement, attributes, release_id)
    attributes
  end

  def maybe_add_tags_to_object(attributes, aha_object)
    if @service.data.send_tags == "1"
      object_tags = aha_object.tags
      attributes[:Tags] = [] if object_tags
      attributes[:Tags] = get_or_create_tag_references(object_tags) if object_tags && !object_tags.empty?
    end
  rescue AhaService::RemoteError => e
    logger.error("Failed to add tags to object: #{e.message}")
  end

  def get_or_create_tag_references(tags)
    # Rally doesn't want escaped quotes or parens
    query_params = build_tag_query(tags)
    query_params = query_params.gsub(" ", "%20").gsub("=", "%3D").gsub("&", "%26")

    params = "query=#{query_params}"
    params << "&workspace=#{rally_url("")}" if @service.data.workspace.present?

    url = rally_secure_url_without_workspace("/tag?#{params}")
    process_response http_get(url) do |document|
      results = document.QueryResult.Results

      tag_refs = results.inject([]){ |acc, res| acc << {_ref: res._ref} }
      results_names = results.map{|obj| obj._refObjectName}
      tags_to_create = tags.select{|tag| !results_names.include? tag}

      created_tags = create_tags tags_to_create

      return tag_refs + created_tags
    end
  end

  # The rally api requires that queries have paren nesting. EX:
  # (( (Name="something") OR (name="something else") ) OR (name="blah"))
  def build_tag_query(tags)
    # The query must contain spaces surrounding the `=`
    tags.map{|tag| "(Name = \"#{tag.gsub('"', '\"')}\")" }.inject {|current, n| "(#{current} OR #{n})"}
  end

  def create_tags(tags)
    params = "workspace=#{rally_url("")}" if @service.data.workspace.present?
    url = rally_secure_url_without_workspace("/tag/create?#{params.to_s}")
    tag_refs = []
    tags.each do |tag_name|
      begin
        body = { Tag: {Name: tag_name } }
        response = http_post url, body.to_json
        process_response response, 200, 201 do |document|
          tag_refs << { _ref: document.CreateResult.Object._ref }
        end
      rescue AhaService::RemoteError => e
        logger.error("Failed to create tag #{tag_name}: #{e.message}")
      end
    end
    tag_refs
  end

  def create_attachments(parent, aha_attachments)
    aha_attachments.each do |aha_attachment|
      rally_attachment_resource.create parent, aha_attachment
    end
  end

  def merge_default_fields(default_fields_data, attributes)
    results = {}
    (default_fields_data || []).each do |field_mapping|
      next unless field_mapping.is_a? Hashie::Mash
      results[field_mapping.field] = field_mapping.value
    end

    results.merge(attributes)
  end

  # Rally will fail the API call if we attempt to assign this to a release that does not exist.
  # Rally will also fail the API call if we attempt to set Release for a user story that is not a leaf node.
  def include_release_if_exists(aha_model, attributes, release_id)
    return if @service.dont_send_releases?
    if @service.feature_element_name == "UserStory"
      return if (aha_model.requirements.try(:length) || 0) > 0
      # do not send if we know for a fact this is not a leaf
      # Rally does not allow you to set the release for a User Story that has other user stories within it
    end

    children_count = get_children(map_to_objectid(aha_model), @service.feature_element_name).length rescue 0
    return if children_count > 0 # do not send if rally has children for this resource

    release_exists = release_id && rally_release_resource.by_id(release_id) rescue false
    return unless release_exists # do not send if rally does not know the release (This means the user deleted it)

    attributes[:Release] = release_id
  end

  def rally_release_resource
    @rally_release_resource ||= RallyReleaseResource.new @service
  end

  def rally_user_resource
    @rally_user_resource ||= RallyUserResource.new @service
  end

  def rally_attachment_resource
    @rally_attachment_resource ||= RallyAttachmentResource.new @service
  end
end
