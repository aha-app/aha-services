class AhaServices::GithubIssues < AhaService
  API_URL = "https://api.github.com"

  def receive_installed
    @meta_data.repos = github_repos
  end

  def receive_create_feature
    milestone_id = create_github_milestone(payload.feature.release)
  end

  def receive_create_release
    create_github_milestone(payload.release)
  end

protected

  def github_repos
    unless (@repos)
      prepare_request
      response = http_get("#{API_URL}/user/repos")
      process_response(response, 200) do |repos|
        @repos = repos
      end
    end
    @repos
  end

  def create_github_milestone(release)
    github_milestones_path = "#{API_URL}/repos/#{data.username}/#{data.repo}/milestones"

    prepare_request

    # If the release is already integrated with a milestone, make sure it still
    # exists.
    if milestone_id = get_integration_field(release.integration_fields, 'id')
      response = http_get "#{github_milestones_path}/#{milestone_id}"
      if response.status == 404
        # Fall through so we recreate the milestone.
      elsif response.status == 200
        return milestone_id # The milestone exists already.
      end
    end

    # Query to see if milestone already exists with same title.
    response = http_get github_milestones_path
    process_response(response, 200) do |milestones|
      milestone = milestones.find {|milestone| milestone['title'] == release.name }
      if milestone
        logger.info("Using existing milestone #{milestone.inspect}")
        api.create_integration_field(release.reference_num, self.class.service_name, :id, milestone['id'])
        return milestone['id']
      end
    end

    milestone = {
      title: release.name,
      description: "Created from Aha! #{release.url}",
      due_on: release.release_date,
      state: release.released ? "closed" : "open"
    }

    response = http_post github_milestones_path, milestone.to_json
    process_response(response, 201) do |new_milestone|
      logger.info("Created milestone #{new_milestone.inspect}")
      milestone_id = new_milestone["id"]

      api.create_integration_field(release.reference_num, self.class.service_name, :id, version_id)
    end

    return milestone_id
  end

  def get_integration_field(integration_fields, field_name)
    return nil if integration_fields.nil?
    field = integration_fields.detect do |f|
      f.service_name == self.class.service_name and f.name == field_name
    end
    field && field.value
  end

  def parse(body)
    if body.nil? or body.length < 2
      {}
    else
      JSON.parse(body)
    end
  end

  def prepare_request
    http.headers['Content-Type'] = 'application/json'
    auth_header
  end
  
  def auth_header
    http.basic_auth data.username, data.password
  end

  def process_response(response, *success_codes, &block)
    if success_codes.include?(response.status)
      yield parse(response.body)
    elsif response.status.between?(400, 499)
      error = parse(response.body)
      raise AhaService::RemoteError, "Error message: #{error['message']}"
    else
      raise AhaService::RemoteError, "Unhandled error: STATUS=#{response.status} BODY=#{response.body}"
    end
  end
end
