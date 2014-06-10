class PivotalTrackerProjectDependentResource < PivotalTrackerResource
  attr_reader :project_id

  def initialize(service, project_id)
    super(service)
    @project_id = project_id
  end

protected

  def append_link(body, parent_id)
    if parent_id
      "#{body}\n\nRequirement of ##{parent_id}."
    else
      body
    end
  end

end
