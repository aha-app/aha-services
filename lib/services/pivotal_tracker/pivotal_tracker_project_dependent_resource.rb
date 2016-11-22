class PivotalTrackerProjectDependentResource < PivotalTrackerResource
  attr_reader :project_id

  def initialize(service, project_id)
    super(service)
    @project_id = project_id
  end

protected

  def append_link(body, parent_id)
    requirement_link = "Requirement of ##{parent_id}"

    if !body.include?(requirement_link) and parent_id and @service.data.mapping == "story-story"
      "#{body}\n\n#{requirement_link}."
    else
      body
    end
  end

end
