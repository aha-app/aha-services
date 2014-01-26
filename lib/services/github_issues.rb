class GithubResource
  API_URL = "https://api.github.com"

  include Networking
  include Errors

  attr_reader :logger

  def initialize(service)
    @service = service
    @logger = service.data.logger || allocate_logger
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

  def self.default_http_options
    @@default_http_options ||= {
      :request => {:timeout => 310, :open_timeout => 5},
      :ssl => {:verify => false, :verify_depth => 5},
      :headers => {}
    }
  end

  def allocate_logger
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::DEBUG
    @logger
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

class GithubMilestoneResource < GithubResource
  def find_by_number(number)
    prepare_request
    response = http_get "#{github_milestones_path}/#{number}"
    response.status == 200 ? parse(response.body) : nil
  end

  def find_by_title(title)
    prepare_request
    response = http_get github_milestones_path
    process_response(response, 200) do |milestones|
      return milestones.find { |milestone| milestone['title'] == title }
    end
  end

  def create(new_milestone)
    prepare_request
    response = http_post github_milestones_path, new_milestone.to_json
    process_response(response, 201) do |milestone|
      return milestone
    end
  end

private

  def github_milestones_path
    "#{API_URL}/repos/#{@service.data.username}/#{@service.data.repo}/milestones"
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

  def find_or_attach_github_milestone(release)
    if milestone = existing_milestone_integrated_with(release)
      milestone
    else
      attach_milestone_to(release)
    end
  end

  def existing_milestone_integrated_with(release)
    if milestone_number = get_integration_field(release.integration_fields, 'number')
      milestone_resource.find_by_number(milestone_number)
    end
  end

  def attach_milestone_to(release)
    unless milestone = milestone_resource.find_by_title(release.name)
      milestone = create_milestone_for(release)
    end
    integrate_release_with_github_milestone(release, milestone)
    milestone
  end

  def create_milestone_for(release)
    new_milestone = {
      title: release.name,
      description: "Created from Aha! #{release.url}",
      due_on: release.release_date,
      state: release.released ? "closed" : "open"
    }
    milestone_resource.create(new_milestone)
  end

protected

  def repo_resource
    @repo_resource ||= GithubRepoResource.new(self)
  end

  def milestone_resource
    @milestone_resource ||= GithubMilestoneResource.new(self)
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

end
