class AhaServices::PivotalTracker < AhaService
  string :api_token, description: "API token from www.pivotaltracker.com"
  install_button
  select :project, collection: -> (meta_data, data) { meta_data.projects.collect { |p| [p.name, p.id] } },
    description: "Tracker project that this Aha! product will integrate with."
  select :integration,
    collection: ->(meta_data, data) { meta_data.projects.detect {|p| p.id.to_s == data.project.to_s }.integrations.collect{|p| [p.name, p.id] } },
    description: "Pivotal integration that you added for Aha!"
  select :mapping, collection: -> {
    [
      ["Feature -> Story, Requirement -> Story", 1],
      ["Feature -> Epic, Requirement -> Story", 2],
      ["Feature -> Story, Requirement -> Task", 3]
    ]
  }

  callback_url description: "URL to add to the Activity Web Hook section in Pivotal Tracker using v5."

  @@api_url = 'https://www.pivotaltracker.com/services/v5'

  def receive_installed
    meta_data.projects = project_resource.all
  end

  def receive_create_feature
    # Add story
    story_id = add_story(data.project, payload.feature)
    payload.feature.requirements.each do |requirement|
      add_story(data.project, requirement, story_id, payload.feature)
    end
  end

  def receive_update_feature
    # Update story
    story_id = get_service_id(payload.feature.integration_fields)
    update_story(data.project, story_id, payload.feature)

    # Create or update each requirement.
    payload.feature.requirements.each do |requirement|
      req_story_id = get_service_id(requirement.integration_fields)
      if req_story_id
        # Update requirement.
        update_story(data.project, req_story_id, requirement, story_id)
      else
        # Create new story for requirement.
        add_story(data.project, requirement, story_id, payload.feature)
      end
    end

  end

  def receive_webhook
    payload.changes.each do |change|
      next unless change.kind == "story"

      begin
        result = api.search_integration_fields(data.integration_id, "id", change.id)
      rescue AhaApi::NotFound
        return # Ignore stories that we don't have Aha! features for.
      end

      if result.feature
        resource = result.feature
        resource_type = "feature"
      elsif result.requirement
        resource = result.requirement
        resource_type = "requirement"
      else
        logger.info("Unhandled resource type")
        next
      end

      if change.new_values and new_state = change.new_values.current_state
        # Update the status.
        api.put(resource.resource, {resource_type => {status: pivotal_to_aha_status(new_state)}})
      else
        # Unhandled change.
      end
    end
  end

protected

  def add_story(project_id, resource, parent_id = nil, parent_resource = nil)
    story_id = nil

    story = {
      name: resource_name(resource),
      description: append_link(html_to_plain(resource.description.body), parent_id),
      story_type: kind_to_story_type(resource.kind || parent_resource.kind),
      created_at: resource.created_at,
      external_id: parent_id ? parent_resource.reference_num : resource.reference_num,
      integration_id: data.integration.to_i,
    }
    file_attachments = upload_attachments(resource.description.attachments | resource.attachments)
    if file_attachments.any?
      story[:comments] = [{file_attachments: file_attachments}]
    end

    created_story = feature_and_requirement_mapping_resource.create_feature_or_requirement(project_id, story)
    api.create_integration_fields(reference_num_to_resource_type(resource.reference_num), resource.reference_num, self.class.service_name, {id: created_story.id, url: created_story.url})
    created_story.id

  end

  def update_story(project_id, story_id, resource, parent_id = nil)
    story = {
      name: resource_name(resource),
      description: append_link(html_to_plain(resource.description.body), parent_id),
    }

    feature_and_requirement_mapping_resource.update_feature_or_requirement(project_id, story_id, story)

    # Add the new attachments.
    new_attachments = update_attachments(project_id, story_id, resource)
    feature_and_requirement_mapping_resource.add_attachments(project_id, story_id, new_attachments)
  end

  def update_attachments(project_id, story_id, resource)
    aha_attachments = resource.attachments.dup | resource.description.attachments.dup

    # Create any attachments that didn't already exist.
    upload_attachments(new_aha_attachments(project_id, story_id, aha_attachments))
  end

  def new_aha_attachments(project_id, story_id, aha_attachments)
    attachment_resource.all_for_story(project_id, story_id).each do |pivotal_attachment|
      # Remove any attachments that match.
      aha_attachments.reject! do |aha_attachment|
        attachments_match(aha_attachment, pivotal_attachment)
      end
    end

    aha_attachments
  end

  def attachments_match(aha_attachment, pivotal_attachment)
    logger.debug("MATCHING: #{aha_attachment.file_name} #{pivotal_attachment.filename} #{aha_attachment.file_size.to_i} #{pivotal_attachment['size'].to_i}")
    aha_attachment.file_name == pivotal_attachment.filename and
      aha_attachment.file_size.to_i == pivotal_attachment['size'].to_i
  end

  def upload_attachments(attachments)
    attachments.collect do |attachment|
      attachment_resource.upload(attachment)
    end
  end

  def project_resource
    @project_resource ||= PivotalTrackerProjectResource.new(self)
  end

  def feature_and_requirement_mapping_resource
    @feature_and_requirement_mapping_resource ||= PivotalTrackerFeatureAndRequirementMappingResource.new(self)
  end

  def attachment_resource
    @attachment_resource ||= PivotalTrackerAttachmentResource.new(self)
  end


  # add token to header
  def prepare_request
    http.headers['Content-Type'] = 'application/json'
    http.headers['X-TrackerToken'] = data.api_token
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

  def process_response(response, *success_codes, &block)
    if success_codes.include?(response.status)
      yield parse(response.body)
    elsif [404, 403, 401, 400].include?(response.status)
      error = parse(response.body)
      error_string = "#{error['code']} - #{error['error']} #{error['general_problem']} #{error['possible_fix']}"

      raise AhaService::RemoteError, "Error code: #{error_string}"
    else
      raise AhaService::RemoteError, "Unhandled error: STATUS=#{response.status} BODY=#{response.body}"
    end
  end

  def parse(body)
    if body.nil? or body.length < 2
      {}
    else
      JSON.parse(body)
    end
  end

  # Get id of current service
  def get_service_id(integration_fields)
    return nil if integration_fields.nil?
    field = integration_fields.detect do |f|
      f.service_name == self.class.service_name and f.name == "id"
    end
    if field
      field.value
    else
      nil
    end
  end

  def pivotal_to_aha_status(status)
    case status
      when "accepted" then "shipped"
      when "delivered" then "ready_to_ship"
      when "finished" then "in_progress"
      when "started" then "in_progress"
      when "rejected" then "in_progress"
      when "unstarted" then "scheduled"
      when "unscheduled" then "under_consideration"
    end
  end

end

