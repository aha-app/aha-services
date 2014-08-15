class GithubResource < GenericResource
  API_URL = "https://api.github.com"

  def prepare_request
    super
    auth_header
  end

  def auth_header
    http.basic_auth @service.data.username, @service.data.password
  end

  def github_http_get_paginated(url, page = 1, previous_response = [], &block)
    response = http_get("#{url}?per_page=100&page=#{page}")
    process_response(response, 200) do |parsed_response|
      if has_paginated_header?(response)
        github_http_get_paginated(url, page + 1, previous_response + parsed_response, &block)
      else
        yield previous_response + parsed_response
      end
    end
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

  def has_paginated_header?(response)
    response.headers['link'] && response.headers['link'].match(/rel=\"next\"/)
  end


end
