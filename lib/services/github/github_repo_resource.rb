class GithubRepoResource < GithubResource
  def all
    unless (@repos)
      prepare_request
      github_http_get_paginated("#{@service.server_url}/user/repos") do |repos|
        @repos = repos
      end
    end
    @repos
  end
end
