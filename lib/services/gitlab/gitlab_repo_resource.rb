class GitlabRepoResource < GitlabResource
  def all
    return @repos if @repos
    prepare_request
    gitlab_http_get_paginated("#{@service.server_url}/projects?owned=true") do |repos|
      @repos = repos
      return repos
    end
  end
end
