class TFSResource < GenericResource

  API_VERSION = "1.0"

  def faraday_builder b
    b.basic_auth(@service.data.user_name, @service.data.user_password)
  end

  def self.default_http_options
    super
    @@default_http_options[:headers]["Content-Type"] = "application/json"
    @@default_http_options
  end

  def process_response(response, *success_codes, &block)
    success_codes = [200] if success_codes == []
    if success_codes.include?(response.status)
      if block_given?
        yield hashie_or_array_of_hashies(response.body)
      else
        return hashie_or_array_of_hashies(response.body)
      end
    elsif response.status == 404
      raise AhaService::RemoteError, "Remote resource was not found."
    elsif response.status == 400
      raise AhaService::RemoteError, "The request was not valid."
    elsif [403, 401].include?(response.status)
      raise_config_error "Credentials are invalid or have insufficent rights."
    else
      raise AhaService::RemoteError, "Unhandled error: STATUS=#{response.status} BODY=#{response.body}"
    end
  end
protected
  def mstfs_url path
    joiner = (path =~ /\?/) ? "&" : "?"
    "https://#{@service.data.account_name}.visualstudio.com/defaultcollection/_apis/#{path}#{joiner}api-version="+self.class::API_VERSION
  end

  def mstfs_project_url project, path
    joiner = (path =~ /\?/) ? "&" : "?"
    "https://#{@service.data.account_name}.visualstudio.com/defaultcollection/#{project}/_apis/#{path}#{joiner}api-version="+self.class::API_VERSION
  end
end
