require 'faraday-cookie_jar'

class RallyResource < GenericResource
  API_URL = "https://rally1.rallydev.com/slm/webservice/v2.0"

  attr_accessor :security_token

  def sanitize_portfolio_item_url(url)
    url.gsub(%r{portfolioitem/\w+/}i, "portfolioitem/")
  end

  def faraday_builder b
    b.headers['Accept'] = "application/json"
    b.headers['Content-Type'] = "application/json"
    b.headers['X-RallyIntegrationName'] = "Aha! Integration"
    b.headers['X-RallyIntegrationVendor'] = "Aha! Labs Inc."
    b.basic_auth @service.data.user_name, @service.data.user_password
    b.use :cookie_jar
  end

  def get_security_token
    url = rally_url_without_workspace "/security/authorize"
    response = http_get url
    process_response response do |document|
      self.security_token = document.OperationResult.SecurityToken
    end
  end

  def process_response(response, *success_codes, &block)
    success_codes = [200] if success_codes == []
    if success_codes.include?(response.status)
      document = hashie_or_array_of_hashies response.body
      result = document.OperationResult || document.CreateResult || document.QueryResult
      if result and result.Errors.size > 0 then
        raise AhaService::RemoteError, "Error: #{result.Errors.join(";")}"
      end
      if block_given?
        yield document
      else
        return document
      end
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
    "#{API_URL}#{maybe_workspace}#{path}#{key}"
  end

  def rally_secure_url path
    get_security_token unless self.security_token
    joiner = (path =~ /\?/) ? "&" : "?"
    "#{API_URL}#{maybe_workspace}#{path}#{joiner}key=#{self.security_token}"
  end

  def maybe_workspace
    if @service.data.workspace.present?
      "/workspace/#{@service.data.workspace}"
    else
      ""
    end
  end

  def maybe_add_workspace_to_object(object)
    if @service.data.workspace.present?
      object[:Workspace] = maybe_workspace
    end
    object
  end

  def rally_url_without_workspace(path)
    joiner = (path =~ /\?/) ? "&" : "?"
    key = self.security_token ? "#{joiner}key=#{self.security_token}" : ""
    "#{API_URL}#{path}#{key}"
  end

  def rally_secure_url_without_workspace(path)
    get_security_token unless self.security_token
    joiner = (path =~ /\?/) ? "&" : "?"
    "#{API_URL}#{path}#{joiner}key=#{self.security_token}"
  end

  def map_to_objectid aha_resource
    aha_resource.integration_fields.find{|field| field.integration_id == @service.data.integration_id.to_s and field.name == "id"}.value.to_i
  rescue
    return nil
  end
end
