class PivotalTrackerTaskResource < PivotalTrackerProjectDependentResource
  def create_from_requirement(requirement, feature, feature_mapping)
    task = {
      description: task_description(requirement, feature_mapping.id),
      created_at: requirement.created_at,
    }
    file_attachments = attachment_resource.upload(requirement.description.attachments | requirement.attachments)
    if file_attachments.any?
      story_resource.update(feature_mapping.id, { comments: [ { file_attachments: file_attachments } ] })
    end

    created_task = create(task, feature_mapping.id)
    api.create_integration_fields(reference_num_to_resource_type(requirement.reference_num), requirement.reference_num, @service.class.service_name, {id: created_task.id})
    created_task
  end

  def update_from_requirement(requirement_mapping, requirement, feature_mapping)
    task = {
      description: task_description(requirement, feature_mapping.id)
    }

    update(requirement_mapping.id, task, feature_mapping.id)

    # Add the new attachments.
    new_attachments = attachment_resource.update(requirement, attachment_resource.all_for_story(feature_mapping.id))
    story_resource.add_attachments(feature_mapping.id, new_attachments)
  end

protected

  def story_resource
    @story_resource ||= PivotalTrackerStoryResource.new(@service, project_id)
  end

  def attachment_resource
    @attachment_resource ||= PivotalTrackerAttachmentResource.new(@service, project_id)
  end

  def create(task, story_id)
    prepare_request
    response = http_post("#{api_url}/projects/#{project_id}/stories/#{story_id}/tasks", task.to_json)

    process_response(response, 200) do |created_task|
      logger.info("Created task #{created_task.id}")
      return created_task
    end
  end

  def update(task_id, task, story_id)
    prepare_request
    response = http_put("#{api_url}/projects/#{project_id}/stories/#{story_id}/tasks/#{task_id}", task.to_json)
    process_response(response, 200) do |updated_task|
      logger.info("Updated task #{task_id}")
    end
  end

  def task_description(requirement, feature_mapping_id)
    [requirement.name, append_link(html_to_plain(requirement.description.body), feature_mapping_id)].join("\n")
  end
end
