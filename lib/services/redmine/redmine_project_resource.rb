class RedmineProjectResource < RedmineResource
  API_LIMIT = 100

  def all
    prepare_request
    @projects = get_all_with_pagination(0)
  end

  private
  def get_all_with_pagination(offset)
    response = http_get "#{@service.data.redmine_url}/projects.json?limit=#{API_LIMIT}&offset=#{offset}"
    process_response response, 200 do |body|
      listed_projects = body['projects'] || []
      if listed_projects.length < API_LIMIT
        listed_projects
      else
        [*listed_projects, *get_all_with_pagination(offset + API_LIMIT)]
      end

    end
  end
end
