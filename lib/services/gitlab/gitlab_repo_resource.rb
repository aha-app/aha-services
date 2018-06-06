class GitlabRepoResource < GitlabResource
  def all
    return @repos if @repos
    prepare_request
    # owned=true necessary after move to v4 gitlab api
    # without it we get all public repos
    # https://docs.gitlab.com/ce/api/v3_to_v4.html
    gitlab_http_get_paginated("#{@service.server_url}/projects?owned=true") do |repos|
      @repos = repos
      return repos
    end
  end
end
