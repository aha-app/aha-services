class AhaServices::Redmine < AhaService
  title 'Redmine'

  string :redmine_url
  string :api_key
  install_button
  select :project,
    collection: -> (meta_data, data) do
      meta_data.projects.collect { |p| [p.name, p.id] }
    end,
    description: "Redmine project that this Aha! product will integrate with."
  select :tracker,
    collection: -> (meta_data, data) do
      meta_data.trackers.collect { |p| [p.name, p.id] }
    end,
    description: "Redmine tracker that new issues should use."
  select :issue_priority,
    collection: -> (meta_data, data) do
      meta_data.issue_priorities.collect { |p| [p.name, p.id] }
    end,
    description: "Default issue priority."

#========
# EVENTS
#=======

  def receive_installed; install_projects; end

  def receive_create_release; create_version; end

  def receive_update_release; update_version; end

  def receive_create_feature
    issue = create_issue payload_fragment: payload.feature
    payload.feature.requirements.each do |requirement|
      create_issue payload_fragment: requirement, parent_id: issue[:id]
    end
  end

  def receive_update_feature
    issue = update_issue payload_fragment: payload.feature
    payload.feature.requirements.each do |requirement|
      if get_integration_field(requirement.integration_fields, 'id')
        update_issue payload_fragment: requirement, parent_id: issue[:id]
      else
        create_issue payload_fragment: requirement, parent_id: issue[:id]
      end
    end
  end

private

#===============
# EVENT METHODS
#=============

  def install_projects
    meta_data.projects = project_resource.all.map { |project| { name: project['name'], id: project['id'] }}
    meta_data.trackers = tracker_resource.all.map { |tracker| { name: tracker['name'], id: tracker['id'] }}
    meta_data.issue_priorities = priority_resource.all.map { |priority| { name: priority['name'], id: priority['id'] }}
  end

  def create_version
    version_resource.create
  end

  def create_issue **options
    check_projects
    issue_resource.create options
  end

  def update_version
    check_projects
    version_resource.update
  end

  def update_issue **options
    check_projects
    issue_resource.update options
  end

#===========
# RESOURCES
#=========

  def project_resource
    @project_resource ||= RedmineProjectResource.new(self)
  end
  
  def tracker_resource
    @tracker_resource ||= RedmineTrackerResource.new(self)
  end

  def priority_resource
    @priority_resource ||= RedminePriorityResource.new(self)
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