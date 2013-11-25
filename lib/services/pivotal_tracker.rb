class AhaServices::PivotalTracker < AhaService
  string :api_token, description: "API token from www.pivotaltracker.com"
  install_button
  select :project, collection: -> (meta_data, data) { meta_data.projects.collect { |p| [p.name, p.id] } }, 
    description: "Tracker project that this Aha! product will integrate with."
  select :integration,
    collection: ->(meta_data, data) { meta_data.projects.detect {|p| p.id.to_s == data.project.to_s }.integrations.collect{|p| [p.name, p.id] } },
    description: "Pivotal integration that you added for Aha!"

  @@api_url = 'https://www.pivotaltracker.com/services/v5'

  def receive_installed
    available_projects = []

    # Get list of projects.
    prepare_request
    response = http_get("#{@@api_url}/projects")
    process_response(response, 200) do |projects|
      projects.each do |project|
        available_projects << {
          :id => project['id'],
          :name => project['name'],
        }
      end
    end
    
    # For each project, get the integrations.
    available_projects.each do |project|
      project[:integrations] = []
      response = http_get("#{@@api_url}/projects/#{project[:id]}/integrations")
      process_response(response, 200) do |integrations|
        integrations.each do |integration|
          project[:integrations] << {
            :id => integration['id'],
            :name => integration['name'],
          }
        end
      end
    end
    
    @meta_data.projects = available_projects
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

  def add_story(project_id, resource, parent_id = nil, parent_resource = nil)
    story_id = nil

    # Upload attachments and collect information.
    attachments = []
    resource.description.attachments.each do |attachment|
      attachments << upload_attachment(attachment)
    end
    resource.attachments.each do |attachment|
      attachments << upload_attachment(attachment)
    end
    
    story = {
      name: resource.name || description_to_title(resource.description.body),
      description: append_link(html_to_plain(resource.description.body), parent_id),
      story_type: kind_to_story_type(resource.kind || parent_resource.kind),
      created_at: resource.created_at,
      external_id: parent_id ? parent_resource.reference_num : resource.reference_num,
      integration_id: data.integration.to_i,
    }
    if attachments.any?
      story[:comments] = [{file_attachments: attachments}]
    end

    prepare_request
    response = http_post("#{@@api_url}/projects/#{project_id}/stories", story.to_json)

    process_response(response, 200) do |new_story|
      story_id = new_story['id']
      story_url = new_story['url']
      logger.info("Created story #{story_id}")

      api.create_integration_field(resource.reference_num, self.class.service_name, :id, story_id)
      api.create_integration_field(resource.reference_num, self.class.service_name, :url, story_url)
    end
    
    story_id
  end

  def update_story(project_id, story_id, resource, parent_id = nil)
    story = {
      name: resource.name || description_to_title(resource.description.body),
      description: append_link(html_to_plain(resource.description.body), parent_id),
    }

    prepare_request
    response = http_put("#{@@api_url}/projects/#{project_id}/stories/#{story_id}", story.to_json)
    process_response(response, 200) do |updated_story|
      logger.info("Updated story #{story_id}")
    end
  end

  def upload_attachment(attachment)
    open(attachment.download_url) do |downloaded_file|
      # Reset Faraday and switch to multipart to do the file upload.
      http_reset 
      http(:encoding => :multipart)
      http.headers['X-TrackerToken'] = data.api_token
      
      file = Faraday::UploadIO.new(downloaded_file, attachment.content_type, attachment.file_name)
      response = http_post("#{@@api_url}/projects/#{data.project}/uploads", {:file => file})
      process_response(response, 200) do |file_attachment|
        return file_attachment
      end
    end
        
  rescue AhaService::RemoteError => e
    logger.error("Failed to upload attachment to #{issue_key}: #{e.message}")
  ensure
    http_reset 
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

end