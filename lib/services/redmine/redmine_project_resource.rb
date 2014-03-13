class RedmineProjectResource < RedmineResource
  def all
    prepare_request
    response = http_get "#{@service.data.redmine_url}/projects.json"
    process_response response, 200 do |body|
      @projects = body['projects']
    end
    @projects
  end
end
