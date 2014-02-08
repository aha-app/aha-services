class GithubResource < GenericResource
  API_URL = "https://api.github.com"

  def prepare_request
    super
    auth_header
  end

  def auth_header
    http.basic_auth @service.data.username, @service.data.password
  end

  def github_http_get_paginated(url)
    http_get("#{url}?per_page=100")
  end

  def process_response(response, *success_codes, &block)
    if success_codes.include?(response.status)
      yield parse(response.body)
    elsif response.status.between?(400, 499)
      error = parse(response.body)
      raise RemoteError, "Error message: #{error['message']}"
    else
      raise RemoteError, "Unhandled error: STATUS=#{response.status} BODY=#{response.body}"
    end
  end

end
