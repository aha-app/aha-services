class PivotalTrackerTaskResource < PivotalTrackerProjectDependentResource
  def create_from_requirement(requirement, feature, feature_mapping)
    task = {
      description: task_description(requirement, feature_mapping.id),
      created_at: requirement.created_at,
    }
    created_task = create(task, feature_mapping.id)
    api.create_integration_fields(reference_num_to_resource_type(requirement.reference_num), 
      requirement.reference_num, @service.data.integration_id, {id: created_task.id, url: feature_mapping.url})
    created_task
  end

  def update_from_requirement(requirement_mapping, requirement, feature_mapping)
    task = {
      description: task_description(requirement, feature_mapping.id)
    }

    update(requirement_mapping.id, task, feature_mapping.id)
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
    [requirement.name, html_to_plain(requirement.description.body)].join("\n")
  end
end
