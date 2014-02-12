class AhaServices::Redmine < AhaService
  title 'Redmine'
  service_name 'redmine_issues'
  install_button

  string :redmine_url
  string :api_key
  select :project,
    collection: -> (meta_data, data) do
      meta_data.projects.collect { |p| [p.name, p.id] }
    end,
    description: "Redmine project that this Aha! product will integrate with."

#========
# EVENTS
#======

  def receive_installed
    install_projects
  end

  def receive_create_release
    create_version
  end

  def receive_create_feature
    response_body = create_issue
    payload.feature.requirements.each do |requirement|
      create_issue requirement, response_body[:issue][:id]
    end
  end

  def receive_update_release
    update_version
  end

  def receive_update_feature
    update_issue
  end

private

#===============
# EVENT METHODS
#=============

  def install_projects
    meta_data.projects = project_resource.all.map { |project| { name: project['name'], id: project['id'] }}
  end

  def create_version
    @meta_data.projects ||= []
    install_projects if @meta_data.projects.empty?
    version_resource.create
  end

  def create_issue payload_fragment=nil, parent_id=nil
    @meta_data.projects ||= []
    unless payload_fragment && parent_id
      issue_resource.create
    else
      issue_resource.create payload_fragment, parent_id
    end
  end

  def update_version
    @meta_data.projects ||= []
    install_projects if @meta_data.projects.empty?
    version_resource.update
  end

  def update_issue
    @meta_data.projects ||= []
    install_projects if @meta_data.projects.empty?
    issue_resource.update
  end

#===========
# RESOURCES
#=========

  def project_resource
    @project_resource ||= RedmineProjectResource.new(self)
  end

  def version_resource
    @version_resource ||= RedmineVersionResource.new(self)
  end

  def issue_resource
    @issue_resource ||= RedmineIssueResource.new(self)
  end

#==================
# REQUEST HANDLING
#================

  def prepare_request
    http.headers['Content-Type'] = 'application/json'
    http.headers['X-Redmine-API-Key'] = data.api_key
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
      Hashie::Mash.new JSON.parse(body)
    end
  end

  def create_integrations reference, **fields
    fields.each do |field, value|
      api.create_integration_field(reference, self.class.service_name, field, value)
    end
  end

#=========
# SUPPORT
#=======

  def find_project project_id
    @meta_data.projects.find {|p| p[:id] == project_id }
  end

  def find_version project_id, version_id
    project = project_id.is_a?(Hash) ? project_id : find_project(project_id)
    project[:versions].find {|v| v[:id] == version_id }
  end

  def kind_to_tracker_id kind
    case kind
    when "bug_fix"
      1 # bug tracker
    when "research"
      3 # support tracker
    else
      2 # feature tracker
    end
  end

end