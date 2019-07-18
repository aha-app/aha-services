class GitlabRepoResource < GitlabResource
  def all
    return @repos if @repos
    prepare_request
    # membership=true necessary after move to v4 gitlab api
    # without it we get all public repos
    # https://docs.gitlab.com/ce/api/v3_to_v4.html
    gitlab_http_get_paginated("#{@service.server_url}/projects?membership=true&with_issues_enabled=true") do |repos|
      @repos = repos
      return repos
    end
  end
end
