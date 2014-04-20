class PivotalTrackerFeatureAndRequirementMappingResource < PivotalTrackerResource

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

  def mapping
    @service.data.mapping
  end
end
