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

  def receive_installed; install_projects; end
  def receive_create_release; create_version; end
  def receive_update_release; update_version; end
  def receive_update_feature; update_issue; end
  def receive_create_feature
    response_body = create_issue
    payload.feature.requirements.each do |requirement|
      create_issue requirement, response_body[:issue][:id]
    end
  end

private

#===============
# EVENT METHODS
#=============

  def install_projects
    meta_data.projects = project_resource.all.map { |project| { name: project['name'], id: project['id'] }}
  end

  def create_version
    version_resource.create
  end

  def create_issue payload_fragment=nil, parent_id=nil
    check_projects
    issue_resource.create payload_fragment, parent_id
  end

  def update_version
    check_projects
    version_resource.update
  end

  def update_issue
    check_projects
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

#=========
# SUPPORT
#=======

  def check_projects
    @meta_data.projects ||= []
    install_projects if @meta_data.projects.empty?
  end

end