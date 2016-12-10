class GitlabRepoResource < GitlabResource
  def all
    unless (@repos)
      prepare_request
      gitlab_http_get_paginated("#{@service.server_url}/projects") do |repos|
        @repos = repos
      end
    end
    @repos
  end
end
