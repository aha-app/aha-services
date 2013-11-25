class AhaServices::PivotalTracker < AhaService
  string :api_token, description: "Api token from www.pivotaltracker.com"
  install_button
  select :project, collection: ->(meta_data) { meta_data.projects.collect { |p| [p.name, p.id] } }

  @@api_url = 'https://www.pivotaltracker.com/services/v5'

  def receive_installed
    available_projects = []

    # get list of projects
    prepare_request
    response = http_get '%s/projects' % [@@api_url]
    process_response(response, 200) do |projects|
      projects.each do |project|
        available_projects << {
          :id => project['id'],
          :name => project['name'],
        }
      end
    end
    @meta_data.projects = available_projects
  end

  def receive_create_feature
    # add story
    story_id = add_story(data.project, payload.feature)
    payload.feature.requirements.each do |requirement|
      add_task(data.project, story_id, requirement)
    end
  end

  def receive_update_feature
    story_id = get_service_id(payload.feature.integration_fields)

    # Update story
    update_story(data.project, story_id, payload.feature)

    # Create or update each requirement.
    payload.feature.requirements.each do |requirement|
      task_id = get_service_id(requirement.integration_fields)
      if task_id
        # Update task.
        update_task(data.project, story_id, task_id, requirement)
      else
        # Create new task.
        add_task(data.project, story_id, requirement)
      end
    end

  end

  def add_story(project_id, resource)
    story_id = nil

    story = {
      name: resource.name,
      description: append_link(strip_html(resource.description.body), resource),
      story_type: 'feature', #feature, bug, chore, release
      created_at: resource.created_at,
    }

    prepare_request
    response = http_post '%s/projects/%s/stories' % [@@api_url, project_id], story.to_json

    process_response(response, 200) do |new_story|
      story_id = new_story['id']
      story_url = new_story['url']
      logger.info("Created story #{story_id}")

      api.create_integration_field(resource.reference_num, self.class.service_name, :id, story_id)
      api.create_integration_field(resource.reference_num, self.class.service_name, :url, story_url)
    end

    story_id
  end

  def update_story(project_id, story_id, resource)

    story = {
      name: resource.name,
      description: append_link(strip_html(resource.description.body), resource),
    }

    prepare_request
    response = http_put '%s/projects/%s/stories/%s' % [@@api_url, project_id, story_id], story.to_json
    process_response(response, 200) do |updated_story|
      logger.info("Updated story #{story_id}")
    end

  end

  def add_task(project_id, story_id, resource)
    task_id = nil

    task = {
      story_id: story_id,
      project_id: project_id,
      description: strip_html(resource.description.body),
      complete: !resource.status.zero?,
    }

    prepare_request
    response = http_post '%s/projects/%s/stories/%s/tasks' % [@@api_url, project_id, story_id], task.to_json

    process_response(response, 200) do |new_task|
      task_id = new_task['id']
      logger.info("Created task #{task_id}")

      api.create_integration_field(resource.reference_num, self.class.service_name, :id, task_id)
    end

    task_id
  end

  def update_task(project_id, story_id, task_id, resource)

    task = {
      description: strip_html(resource.description.body),
      complete: !resource.status.zero?,
    }

    prepare_request
    response = http_put '%s/projects/%s/stories/%s/tasks/%s' % [@@api_url, project_id, story_id, task_id], task.to_json
    process_response(response, 200) do |updated_task|
      logger.info("Updated task #{task_id}")
    end

  end

  # add token to header
  def prepare_request
    http.headers['Content-Type'] = 'application/json'
    http.headers['X-TrackerToken'] = data.api_token
  end

  # strip html
  def strip_html(str)
    str = str.gsub(/<br\W*?\/>/, "\n")
    str.gsub(/<\/?[^>]*>/, "")
  end

  def append_link(body, resource)
    "#{body}\n\nCreated from Aha! #{resource.url}"
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

  # get id of current service
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