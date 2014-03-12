class GithubRepoResource < GithubResource
  def all
    unless (@repos)
      prepare_request
      response = github_http_get_paginated("#{API_URL}/user/repos")
      process_response(response, 200) do |repos|
        @repos = repos
      end
      
      # Also get all organization repos.
      response = github_http_get_paginated("#{API_URL}/user/orgs")
      process_response(response, 200) do |orgs|
        orgs.each do |org|
          response = github_http_get_paginated("#{API_URL}/orgs/#{org['login']}/repos")
          process_response(response, 200) do |repos|
            @repos.concat(repos)
          end
        end
      end
      
    end
    @repos
  end
end
