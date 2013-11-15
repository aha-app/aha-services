class AhaServices::Pivotaltracker < AhaService
  string :api_token, description: "Api token from pivotaltracker.com"
  install_button
  select :project, collection: ->(meta_data) { meta_data.projects.collect { |p| [p.name, p.id] } }
  #select :integration, collection: ->(meta_data, data) { meta_data.projects.collect{|p| [p.name, p.id] } }
  #callback_url description: "URL to add to the webhooks section of Pivotaltracker."

  @@api_url = 'https://www.pivotaltracker.com/services/v5'

  def receive_installed

    prepare_request

    available_projects = []
    # get list of projects
    response = http_get '%s/projects' % [@@api_url]
    process_response(response, 200) do |projects|
      projects.each do |project|
        projects_integrations = []

=begin
        response = http_get '%s/projects/%s/integrations' % [@@api_url, project['id']]
        process_response(response, 200) do |integrations|
          integrations.each do |integration|
            projects_integrations << {:id => integration['id'], :name => integration['name']}
          end
        end
=end

        available_projects << {:id => project['id'], :name => project['name'], :integrations => projects_integrations}
      end
    end
    @meta_data.projects = available_projects
  end

  def receive_create_feature
    version_id = get_service_id(payload.feature.release.integration_fields)
    # add story
    story_id = add_story(data.project, payload.feature, version_id)
    payload.feature.requirements.each do |requirement|
      add_task(data.project, story_id, requirement)
    end
  end

  def receive_update_feature
    version_id = get_service_id(payload.feature.release.integration_fields)
    story_id = get_service_id(payload.feature.integration_fields)

    # Update story
    update_story(data.project, story_id, payload.feature, version_id)

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

  def add_story(project_id, resource, version_id)
    story_id = nil

    story = {
        name: resource.name,
        description: append_link(strip_html(resource.description.body), resource),
        cl_numbers: version_id,
        story_type: 'feature', #feature, bug, chore, release
        created_at: resource.created_at,
        #external_id: resource.id,
        #integration_id: '',
        #tasks: convert_requirements_to_tasks(resource.requirements),
        #deadline: resource,
        #current_state:'',  #accepted, delivered, finished, started, rejected, unstarted, unscheduled
    }

    prepare_request
    response = http_post '%s/projects/%s/stories' % [@@api_url, project_id], story.to_json

    process_response(response, 200) do |new_story|
      story_id = new_story['id']
      story_url = new_story['url']
      logger.info("Created story #{story_id}")

      #api.create_integration_field(resource.reference_num, self.class.service_name, :id, story_id)
      #api.create_integration_field(resource.reference_num, self.class.service_name, :url, story_url)
    end

    story_id
  end

  def update_story(project_id, story_id, resource, version_id)

    story = {
        name: resource.name,
        description: append_link(strip_html(resource.description.body), resource),
    }

    if version_id
      story[:cl_numbers] = version_id
    end

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

      #api.create_integration_field(resource.reference_num, self.class.service_name, :id, task_id)
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
    elsif response.status == 404 || response.status == 403 || response.status == 401 || response.status == 400
      errors = parse(response.body)
      error_string = errors.error
      if !errors.general_problem.nil?
        error_string + ' ' + errors.general_problem
      end
      if !errors.possible_fix.nil?
        error_string + ' ' + errors.possible_fix
      end

      raise AhaService::RemoteError, "Error code: #{errors.code} - #{error_string}"
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