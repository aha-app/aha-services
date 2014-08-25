class PivotalTrackerStoryResource < PivotalTrackerProjectDependentResource
  def create_from_feature(feature)
    create_from_resource(feature)
  end

  def create_from_requirement(requirement, feature, feature_mapping)
    create_from_resource(requirement, feature, feature_mapping)
  end

  def update_from_feature(feature_mapping, feature)
    update_from_resource(feature_mapping, feature)
  end

  def update_from_requirement(requirement_mapping, requirement, feature_mapping)
    update_from_resource(requirement_mapping, requirement, feature_mapping)
  end

  def add_attachments(story_id, new_attachments)
    if new_attachments.any?
      response = http_post("#{api_url}/projects/#{project_id}/stories/#{story_id}/comments", {file_attachments: new_attachments}.to_json)
      process_response(response, 200) do |updated_story|
        logger.info("Updated story #{story_id}")
      end
    end
  end

  def update(story_id, story)
    prepare_request
    response = http_put("#{api_url}/projects/#{project_id}/stories/#{story_id}", story.to_json)
    process_response(response, 200) do |updated_story|
      logger.info("Updated story #{story_id}")
    end
  end

protected

  def create(story)
    prepare_request
    response = http_post("#{api_url}/projects/#{project_id}/stories", story.to_json)

    process_response(response, 200) do |created_story|
      logger.info("Created story #{created_story.id}")
      return created_story
    end
  end

  def add_attachments(story_id, new_attachments)
    if new_attachments.any?
      response = http_post("#{api_url}/projects/#{project_id}/stories/#{story_id}/comments", {file_attachments: new_attachments}.to_json)
      process_response(response, 200) do |updated_story|
        logger.info("Updated story #{story_id}")
      end
    end
  end

  def attachment_resource
    @attachment_resource ||= PivotalTrackerAttachmentResource.new(@service, project_id)
  end

  def create_from_resource(resource, parent_resource = nil, parent_mapping = nil)
    story = {
      name: resource_name(resource),
      description: append_link(html_to_markdown(resource.description.body), parent_mapping && parent_mapping.id),
      story_type: kind_to_story_type(resource.kind || parent_resource.kind),
      created_at: resource.created_at,
      external_id: parent_resource ? parent_resource.reference_num : resource.reference_num,
      integration_id: @service.data.integration.to_i
    }
    file_attachments = attachment_resource.upload(resource.description.attachments | resource.attachments)
    if file_attachments.any?
      story[:comments] = [{file_attachments: file_attachments}]
    end

    if parent_mapping && parent_mapping.label && parent_mapping.label.id
      story[:label_ids] = [parent_mapping.label.id]
    end

    created_story = create(story)
    api.create_integration_fields(reference_num_to_resource_type(resource.reference_num), resource.reference_num, @service.class.service_name, {id: created_story.id, url: created_story.url})
    created_story
  end

  def update_from_resource(resource_mapping, resource, parent_mapping = nil)
    story = {
      name: resource_name(resource),
      description: append_link(html_to_markdown(resource.description.body), parent_mapping && parent_mapping.id)
    }

    update(resource_mapping.id, story)

    # Add the new attachments.
    new_attachments = attachment_resource.update(resource, attachment_resource.all_for_story(resource_mapping.id))
    add_attachments(resource_mapping.id, new_attachments)
  end

  def kind_to_story_type(kind)
    @service.data.feature_kinds[kind]
  end
end
