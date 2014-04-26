class PivotalTrackerTaskResource < PivotalTrackerProjectDependentResource
  def create_from_requirement(requirement, feature, feature_mapping)
    task = {
      description: task_description(requirement, feature_mapping.id),
      created_at: resource.created_at,
      story_id: feature_mapping.id
    }
    if file_attachments.any?
      # story[:comments] = [{file_attachments: file_attachments}]
    end

    created_task = create(task)
    api.create_integration_fields(reference_num_to_resource_type(requirement.reference_num), requirement.reference_num, @service.class.service_name, {id: created_task.id})
    created_task
  end

  def update_from_requirement(requirement_mapping, requirement, feature_mapping)
    task = {
      description: task_description(requirement, feature_mapping.id)
    }

    update(requirement_mapping.id, task)

    # Add the new attachments.
    # new_attachments = attachment_resource.update(resource, attachment_resource.all_for_story(resource_mapping.id))
    # add_attachments(resource_mapping.id, new_attachments)
  end

protected

  # def create(story)
  #   prepare_request
  #   response = http_post("#{api_url}/projects/#{project_id}/stories", story.to_json)

  #   process_response(response, 200) do |created_story|
  #     logger.info("Created story #{created_story.id}")
  #     return created_story
  #   end
  # end

  # def update(story_id, story)
  #   prepare_request
  #   response = http_put("#{api_url}/projects/#{project_id}/stories/#{story_id}", story.to_json)
  #   process_response(response, 200) do |updated_story|
  #     logger.info("Updated story #{story_id}")
  #   end
  # end

  # def add_attachments(story_id, new_attachments)
  #   if new_attachments.any?
  #     response = http_post("#{api_url}/projects/#{project_id}/stories/#{story_id}/comments", {file_attachments: new_attachments}.to_json)
  #     process_response(response, 200) do |updated_story|
  #       logger.info("Updated story #{story_id}")
  #     end
  #   end
  # end

  # def attachment_resource
  #   @attachment_resource ||= PivotalTrackerAttachmentResource.new(@service, project_id)
  # end

  def task_description(requirement, feature_mapping_id)
    [requirement.name, append_link(html_to_plain(requirement.description.body), feature_mapping_id)].join("\n")
  end
end
