class BitbucketResource < GenericResource
  API_URL = "https://bitbucket.org/api/1.0"

  def prepare_request
    super
    auth_header
  end

  def auth_header
    http.basic_auth @service.data.username, @service.data.password
  end

  def bitbucket_http_get(url)
    prepare_request
    response = http_get(url)
    process_response(response, 200) do |parsed_response|
      parsed_response
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

end

