require 'faraday-cookie_jar'

class RallyResource < GenericResource
  API_URL = "https://rally1.rallydev.com/slm/webservice/v2.0/"

  attr_accessor :security_token

  def faraday_builder b
    b.headers['Accept'] = "application/json"
    b.headers['Content-Type'] = "application/json"
    b.headers['X-RallyIntegrationName'] = "Aha! Integration"
    b.headers['X-RallyIntegrationVendor'] = "Aha! Labs Inc."
    b.basic_auth @service.data.user_name, @service.data.user_password
    b.use :cookie_jar
  end

  def get_security_token
    url = rally_url "/security/authorize"
    response = http_get url
    if response.status == 200 then
      document = hashie_or_array_of_hashies response.body
      self.security_token = document.OperationResult.SecurityToken
      return
    elsif response.status == 401 then
      raise_config_error "Invalid credentials."
    end
    raise AhaService::RemoteError, "Error code: #{response.status}"
  end

  def process_response(response, *success_codes, &block)
    if success_codes.include?(response.status)
      yield hashie_or_array_of_hashies(response.body) if block_given?
    elsif [403, 401].include?(response.status)
      raise_config_error "Authentication or authorization failed!"
    elsif [404, 400].include?(response.status)
      obj = hashie_or_array_of_hashies(response.body)
      result = obj.OperationResult || obj.CreateResult || obj.QueryResult
      error_string = result.Errors.join("; ") rescue "Unknown error"

      raise AhaService::RemoteError, "Error code: #{error_string}"
    else
      raise AhaService::RemoteError, "Unhandled error: STATUS=#{response.status} BODY=#{response.body}"
    end
  end

  def rally_url path
    joiner = (path =~ /\?/) ? "&" : "?"
    key = self.security_token ? "#{joiner}key=#{self.security_token}" : ""
    "#{API_URL}#{path}#{key}"
  end

  def rally_secure_url path
    joiner = (path =~ /\?/) ? "&" : "?"
    raise "Missing security token" unless self.security_token
    "#{API_URL}#{path}#{joiner}key=#{self.security_token}"
  end
end
