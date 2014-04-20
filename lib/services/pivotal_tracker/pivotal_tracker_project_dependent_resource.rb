class PivotalTrackerProjectDependentResource < PivotalTrackerResource
  attr_reader :project_id

  def initialize(service, project_id)
    super(service)
    @project_id = project_id
  end
end
