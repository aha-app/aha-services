class AhaServices::GithubIssues < AhaService
  API_URL = "https://api.github.com"

  def receive_installed
    available_repos = []

    prepare_request
    response = http_get("#{API_URL}/user/repos")
    process_response(response, 200) do |repos|
      repos.each do |repo|
        available_repos << {
          id: repo['id'],
          name: repo['name']
        }
      end
    end

    @meta_data.repos = available_repos
  end

  private

  def parse(body)
    if body.nil? or body.length < 2
      {}
    else
      JSON.parse(body)
    end
  end

  def prepare_request
    http.headers['Content-Type'] = 'application/json'
    auth_header
  end
  
  def auth_header
    http.basic_auth data.username, data.password
  end

  def process_response(response, *success_codes, &block)
    if success_codes.include?(response.status)
      yield parse(response.body)
    elsif response.status.between?(400, 499)
      error = parse(response.body)
      raise AhaService::RemoteError, "Error message: #{error.message}"
    else
      raise AhaService::RemoteError, "Unhandled error: STATUS=#{response.status} BODY=#{response.body}"
    end
  end
end
