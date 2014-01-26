class GithubResource
  API_URL = "https://api.github.com"

  include Networking
  include Errors

  def initialize(service)
    @service = service
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
    http.basic_auth @service.data.username, @service.data.password
  end

  def process_response(response, *success_codes, &block)
    if success_codes.include?(response.status)
      yield parse(response.body)
    elsif response.status.between?(400, 499)
      error = parse(response.body)
      raise RemoteError, "Error message: #{error['message']}"
    else
      raise RemoteError, "Unhandled error: STATUS=#{response.status} BODY=#{response.body}"
    end
  end
end

class GithubRepoResource < GithubResource
  def all
    unless (@repos)
      prepare_request
      response = http_get("#{API_URL}/user/repos")
      process_response(response, 200) do |repos|
        @repos = repos
      end
    end
    @repos
  end
end

class AhaServices::GithubIssues < AhaService
  API_URL = "https://api.github.com"

  def receive_installed
    meta_data.repos = repo_resource.all
  end

  def receive_create_feature
    milestone = find_or_attach_github_milestone(payload.feature.release)
  end

  def receive_create_release
    find_or_attach_github_milestone(payload.release)
  end

protected

  def repo_resource
    @repo_resource ||= GithubRepoResource.new(self)
  end

  def find_or_attach_github_milestone(release)
    if milestone = existing_milestone_integrated_with(release)
      milestone
    else
      attach_milestone_to(release)
    end
  end

  def existing_milestone_integrated_with(release)
    if milestone_number = get_integration_field(release.integration_fields, 'number')
      find_github_milestone_by_number(milestone_number)
    end
  end

  def find_github_milestone_by_number(number)
    prepare_request
    response = http_get "#{github_milestones_path}/#{number}"
    response.status == 200 ? parse(response.body) : nil
  end

  def attach_milestone_to(release)
    if milestone = find_github_milestone_by_title(release.name)
      integrate_release_with_github_milestone(release, milestone)
      milestone
    else
      new_milestone_for(release)
    end
  end

  def find_github_milestone_by_title(title)
    prepare_request
    response = http_get github_milestones_path
    process_response(response, 200) do |milestones|
      return milestones.find { |milestone| milestone['title'] == title }
    end
  end

  def new_milestone_for(release)
    new_milestone = {
      title: release.name,
      description: "Created from Aha! #{release.url}",
      due_on: release.release_date,
      state: release.released ? "closed" : "open"
    }
    prepare_request
    response = http_post github_milestones_path, new_milestone.to_json
    process_response(response, 201) do |milestone|
      integrate_release_with_github_milestone(release, milestone)
      return milestone
    end
  end

  def integrate_release_with_github_milestone(release, milestone)
    api.create_integration_field(release.reference_num, self.class.service_name, :number, milestone['number'])
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

private
  def github_milestones_path
    "#{API_URL}/repos/#{data.username}/#{data.repo}/milestones"
  end
end
