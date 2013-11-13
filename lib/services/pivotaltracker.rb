class AhaServices::Pivotaltracker < AhaService
  string :server_url, description: "URL for the Jira server, without the trailing slash, e.g. https://bigaha.atlassian.net"
  string :username
  password :password
  install_button
  select :project, collection: ->(meta_data, data) { meta_data.projects.collect{|p| [p.name, p['key']] } }
  internal :feature_status_mapping
  internal :resolution_mapping

  callback_url description: "URL to add to the webhooks section of Jira."

  @@api_url = 'https://www.pivotaltracker.com/services/v5'

  def receive_installed
    prepare_request
    response = http_get '%s/rest/api/2/issue/createmeta' % [data.server_url]
    projects = []
    process_response(response, 200) do |meta|
      meta['projects'].each do |project|
        issue_types = []

        # Get the statuses.
        status_response = http_get '%s/rest/api/2/project/%s/statuses' % [data.server_url, project['key']]
        if status_response.status == 404
          # In Jira 5.0 the status is not associated with each issue type.
          status_response = http_get '%s/rest/api/2/status' % [data.server_url]
          process_response(status_response, 200) do |status_meta|
            statuses = []
            status_meta.each do |status|
              statuses << {:id => status['id'], :name => status['name']}
            end

            project['issuetypes'].each do |issue_type|
              issue_types << {:id => issue_type['id'], :name => issue_type['name'],
                              :subtask => issue_type['subtask'], :statuses => statuses}
            end
          end
        else
          process_response(status_response, 200) do |status_meta|
            status_meta.each do |issue_type|
              statuses = []
              issue_type['statuses'].each do |status|
                statuses << {:id => status['id'], :name => status['name']}
              end

              issue_types << {:id => issue_type['id'], :name => issue_type['name'],
                              :subtask => issue_type['subtask'], :statuses => statuses}
            end
          end
        end

        projects << {:id => project['id'], :key => project['key'],
                     :name => project['name'], :issue_types => issue_types}
      end
    end
    @meta_data.projects = projects

    response = http_get '%s/rest/api/2/resolution' % [data.server_url]
    resolutions = []
    process_response(response, 200) do |meta|
      meta.each do |resolution|
        resolutions << {:id => resolution['id'], :name => resolution['name']}
      end
    end
    @meta_data.resolutions = resolutions

  end

  def receive_create_feature
    add_story payload.feature, data.project_id, nil
  end

  def add_story(resource, project_id, version_id)
    story_id = nil

    story = {
        name: resource.name,
        description: append_link(strip_html(resource.description.body), resource),
        cl_numbers: version_id,
        #deadline:'',
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
      p new_story
      #logger.info("Created issue #{issue_id} / #{issue_key}")
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
    elsif response.status == 401 || response.status == 403
      raise AhaService::RemoteError, "Authentication failed: #{response.status} #{response.headers['X-Authentication-Denied-Reason']}"
    elsif response.status == 400
      errors = parse(response.body)
      error_string = errors["errorMessages"].join(", ") +
          errors["errors"].map {|k, v| "#{k}: #{v}" }.join(", ")
      raise AhaService::RemoteError, "Data not accepted: #{error_string}"
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

end