class PivotalTrackerResource < GenericResource
  API_URL = "https://www.pivotaltracker.com/services/v5"

  def api_url
    if @service.data.api_host.present?
      "https://#{@service.data.api_host}/services/v5"
    else
      API_URL
    end
  end

  def prepare_request
    super
    auth_header
  end

  def auth_header
    http.headers['Content-Type'] = 'application/json'
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

  def get_resource(integration_fields)
    return nil if integration_fields.nil?
    resource = Hashie::Mash.new
    integration_fields
      .select do |f|
        f.service_name == @service.class.service_name
      end
      .each do |f|
        resource[f.name] = f.value
      end
    resource
  end

end
