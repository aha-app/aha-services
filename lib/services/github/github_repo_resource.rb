class GithubRepoResource < GithubResource
  def all
    unless (@repos)
      prepare_request
      response = github_http_get_paginated("#{API_URL}/user/repos")
      process_response(response, 200) do |repos|
        @repos = repos
      end
    end
    @repos
  end
end
