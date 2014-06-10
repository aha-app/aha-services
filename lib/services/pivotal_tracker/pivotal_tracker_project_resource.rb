class PivotalTrackerProjectResource < PivotalTrackerResource
  def all
    # Get list of projects.
    prepare_request
    response = http_get("#{api_url}/projects")
    process_response(response, 200) do |projects|
      @projects = projects
    end

    # For each project, get the integrations.
    @projects.each do |project|
      response = http_get("#{api_url}/projects/#{project.id}/integrations")
      process_response(response, 200) do |integrations|
        project.integrations = integrations
      end
    end

    @projects
  end
end
