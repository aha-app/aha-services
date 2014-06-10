class PivotalTrackerEpicResource < PivotalTrackerProjectDependentResource
  def create_from_feature(feature)
    epic = {
      name: resource_name(feature),
      description: html_to_markdown(feature.description.body),
      created_at: feature.created_at
    }
    file_attachments = attachment_resource.upload(feature.description.attachments | feature.attachments)
    if file_attachments.any?
      epic[:comments] = [{file_attachments: file_attachments}]
    end

    created_epic = create(epic)
    api.create_integration_fields(
      reference_num_to_resource_type(feature.reference_num),
      feature.reference_num,
      @service.class.service_name,
      { id: created_epic.id,
        url: created_epic.url,
        label_id: created_epic.label.id }
    )
    created_epic
  end

  def update_from_feature(feature_mapping, feature)
    epic = {
      name: resource_name(feature),
      description: html_to_markdown(feature.description.body)
    }

    update(feature_mapping.id, epic)

    # Add the new attachments.
    new_attachments = attachment_resource.update(feature, attachment_resource.all_for_epic(feature_mapping.id))
    add_attachments(feature_mapping.id, new_attachments)
  end

protected

  def create(epic)
    prepare_request
    response = http_post("#{api_url}/projects/#{project_id}/epics", epic.to_json)

    process_response(response, 200) do |created_epic|
      logger.info("Created epic #{created_epic.id}")
      return created_epic
    end
  end

  def update(epic_id, epic)
    prepare_request
    response = http_put("#{api_url}/projects/#{project_id}/epics/#{epic_id}", epic.to_json)
    process_response(response, 200) do |updated_epic|
      logger.info("Updated epic #{epic_id}")
    end
  end

  def add_attachments(epic_id, new_attachments)
    if new_attachments.any?
      response = http_post("#{api_url}/projects/#{project_id}/epics/#{epic_id}/comments", {file_attachments: new_attachments}.to_json)
      process_response(response, 200) do |updated_epic|
        logger.info("Updated epic #{epic_id}")
      end
    end
  end

  def attachment_resource
    @attachment_resource ||= PivotalTrackerAttachmentResource.new(@service, project_id)
  end

end
