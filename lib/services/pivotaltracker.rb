class AhaServices::Pivotaltracker < AhaService
  string :api_token, description: "Api token from pivotaltracker.com"
  install_button
  select :project, collection: ->(meta_data, data) { meta_data.projects.collect{|p| [p.name, p.id] } }
  callback_url description: "URL to add to the webhooks section of Pivotaltracker."

  @@api_url = 'https://www.pivotaltracker.com/services/v5'

  def receive_installed
    prepare_request
    response = http_get '%s/projects' % [@@api_url]
    available_projects = []
    process_response(response, 200) do |projects|
      projects.each do |project|
        available_projects << {:id => project['id'], :name => project['name']}
      end
    end
    @meta_data.projects = available_projects
    p  @meta_data.projects
  end

  def receive_create_feature
    version_id = get_service_id(payload.feature.release.integration_fields)
    add_story payload.feature, data.project, version_id
  end

  def add_story(resource, project_id, version_id)
    story_id = nil

    story = {
        name: resource.name,
        description: append_link(strip_html(resource.description.body), resource),
        cl_numbers: version_id,
        #deadline: resource,
        #current_state:'',  #accepted, delivered, finished, started, rejected, unstarted, unscheduled
        story_type: 'feature', #feature, bug, chore, release
        created_at: resource.created_at,
        #external_id: resource.id,
        #integration_id: '',
        tasks: convert_requirements_to_tasks(resource.requirements),
        #accepted_at: '',
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

  def convert_requirements_to_tasks(requirements)
    tasks = []
    requirements.each do |requirement|
      tasks << {
          description: strip_html(requirement.description.body),
          complete: !requirement.status.zero?,
      }
    end

    tasks
  end

  def process_response(response, *success_codes, &block)
    if success_codes.include?(response.status)
      yield parse(response.body)
    elsif response.status == 404 ||  response.status == 403 ||  response.status ==  401 || response.status ==  400
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