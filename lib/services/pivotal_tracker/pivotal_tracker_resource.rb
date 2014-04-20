class PivotalTrackerResource < GenericResource
  API_URL = "https://www.pivotaltracker.com/services/v5"

  def api_url
    API_URL
  end

  def prepare_request
    super
    auth_header
  end

  def auth_header
    http.headers['X-TrackerToken'] = @service.data.api_token
  end

  def process_response(response, *success_codes, &block)
    if success_codes.include?(response.status)
      yield hashie_or_array_of_hashies(response.body) if block_given?
    elsif [404, 403, 401, 400].include?(response.status)
      error = hashie_or_array_of_hashies(response.body)
      error_string = "#{error.code} - #{error.error} #{error.general_problem} #{error.possible_fix}"

      raise AhaService::RemoteError, "Error code: #{error_string}"
    else
      raise AhaService::RemoteError, "Unhandled error: STATUS=#{response.status} BODY=#{response.body}"
    end
  end

end
