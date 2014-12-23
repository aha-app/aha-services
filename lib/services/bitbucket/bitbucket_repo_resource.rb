class BitbucketRepoResource < BitbucketResource
  def all
    @repos ||= bitbucket_http_get("#{API_URL}/user/repositories")
  end
end
