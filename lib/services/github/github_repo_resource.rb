class GithubRepoResource < GithubResource
  def all
    unless (@repos)
      prepare_request
      response = http_get("#{API_URL}/user/repos?per_page=100")
      process_response(response, 200) do |repos|
        @repos = repos
      end
    end
    @repos
  end
end
