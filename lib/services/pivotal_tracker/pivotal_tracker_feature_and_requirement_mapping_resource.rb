class PivotalTrackerFeatureAndRequirementMappingResource < PivotalTrackerResource

  def create_feature(project, feature)
    # Add story
    story_id = add_story(project, feature)
    feature.requirements.each do |requirement|
      add_story(project, requirement, story_id, feature)
    end
  end

  def create_feature_or_requirement(project_id, story)
    prepare_request
    response = http_post("#{api_url}/projects/#{project_id}/stories", story.to_json)

    process_response(response, 200) do |created_story|
      logger.info("Created story #{created_story.id}")
      return created_story
    end
  end

  def update_feature_or_requirement(project_id, story_id, story)
    prepare_request
    response = http_put("#{api_url}/projects/#{project_id}/stories/#{story_id}", story.to_json)
    process_response(response, 200) do |updated_story|
      logger.info("Updated story #{story_id}")
    end
  end

  def add_attachments(project_id, story_id, new_attachments)
    if new_attachments.any?
      response = http_post("#{api_url}/projects/#{project_id}/stories/#{story_id}/comments", {file_attachments: new_attachments}.to_json)
      process_response(response, 200) do |updated_story|
        logger.info("Updated story #{story_id}")
      end
    end
  end

private

  def attachment_resource
    @attachment_resource ||= PivotalTrackerAttachmentResource.new(@service)
  end

  def add_story(project_id, resource, parent_id = nil, parent_resource = nil)
    story_id = nil

    story = {
      name: resource_name(resource),
      description: append_link(html_to_plain(resource.description.body), parent_id),
      story_type: kind_to_story_type(resource.kind || parent_resource.kind),
      created_at: resource.created_at,
      external_id: parent_id ? parent_resource.reference_num : resource.reference_num,
      integration_id: @service.data.integration.to_i,
    }
    file_attachments = upload_attachments(resource.description.attachments | resource.attachments)
    if file_attachments.any?
      story[:comments] = [{file_attachments: file_attachments}]
    end

    created_story = create_feature_or_requirement(project_id, story)
    api.create_integration_fields(reference_num_to_resource_type(resource.reference_num), resource.reference_num, @service.class.service_name, {id: created_story.id, url: created_story.url})
    created_story.id

  end

  def upload_attachments(attachments)
    attachments.collect do |attachment|
      attachment_resource.upload(attachment)
    end
  end

  def append_link(body, parent_id)
    if parent_id
      "#{body}\n\nRequirement of ##{parent_id}."
    else
      body
    end
  end

  def kind_to_story_type(kind)
    case kind
    when "new", "improvement"
      "feature"
    when "bug_fix"
      "bug"
    when "research"
      "chore"
    else
      "feature"
    end
  end

  def mapping
    @service.data.mapping
  end
end
