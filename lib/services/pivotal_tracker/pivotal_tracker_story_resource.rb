class PivotalTrackerStoryResource < PivotalTrackerProjectDependentResource
  def create_from_feature(feature, initiative_mapping = nil)
    if initiative_mapping
      create_from_resource(feature, nil, initiative_mapping)
    else
      create_from_resource(feature)
    end
  end

  def create_from_requirement(requirement, feature, feature_mapping)
    create_from_resource(requirement, feature, feature_mapping)
  end

  def update_from_feature(feature_mapping, feature, initiative_mapping = nil)
    update_from_resource(feature_mapping, feature, initiative_mapping)
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
  
  def find_by_id(story_id)
    prepare_request
    response = http_get "#{api_url}/projects/#{project_id}/stories/#{story_id}"
    found_resource(response)
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
      description: append_link(html_to_markdown(resource.description.body, true), parent_mapping && parent_mapping.id),
      story_type: kind_to_story_type(resource.workflow_kind.try(:id) || parent_resource.workflow_kind.id),
      created_at: resource.created_at,
      external_id: parent_resource ? parent_resource.reference_num : resource.reference_num,
      integration_id: @service.data.integration.to_i
    }
    if resource.work_units == 20 # Only send estimates if using story points
      story[:estimate] = resource.original_estimate
    end
    
    file_attachments = attachment_resource.upload(resource.description.attachments | resource.attachments)
    if file_attachments.any?
      story[:comments] = [{file_attachments: file_attachments}]
    end

    if parent_mapping
      label_id = parent_mapping.label_id || parent_mapping.label.try(:id)
      if label_id.present?
        story[:label_ids] = [label_id.to_i]
      end
    end

    created_story = create(story)
    api.create_integration_fields(reference_num_to_resource_type(resource.reference_num), resource.reference_num, @service.data.integration_id, {id: created_story.id, url: created_story.url})
    created_story
  end

  def update_from_resource(resource_mapping, resource, parent_mapping = nil)
    story = {
      name: resource_name(resource),
      description: append_link(html_to_markdown(resource.description.body, true), parent_mapping && parent_mapping.id)
    }

    if parent_mapping
      label_id = parent_mapping.label_id || parent_mapping.label.try(:id)
      if label_id.present?
        # We need to read the current labels from the story so we can merge our
        # label.
        existing_story = find_by_id(resource_mapping.id)
        
        story[:label_ids] = existing_story.labels.collect {|l| l.id } | [label_id.to_i]
        
        # TODO: Unfortunately PT doesn't make it easy for us to remove the old epic, so now the story will be in two epics.
      end
    end
    
    updated_story = update(resource_mapping.id, story)

    # Add the new attachments.
    new_attachments = attachment_resource.update(resource, attachment_resource.all_for_story(resource_mapping.id))
    add_attachments(resource_mapping.id, new_attachments)
    
    updated_story
  end

  def kind_to_story_type(kind)
    if @service.data.feature_kinds
      @service.data.feature_kinds[kind]
    else
      "feature"
    end
  end
end
