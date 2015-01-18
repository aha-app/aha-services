class BugzillaResource < GenericResource
  attr_reader :service
  
  def faraday_builder b
    b.options.params_encoder = Faraday::FlatParamsEncoder
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
      raise_config_error "The API key is invalid or has insufficent rights."
    else
      raise AhaService::RemoteError, "Unhandled error: STATUS=#{response.status} BODY=#{response.body}"
    end
  end

  def get_product
    service.meta_data.products.find{|p| p.id.to_s == service.data.product }
  end

  def get_component
    get_product().components.find{|c| c.id.to_s == service.data.component }
  end

  def bugzilla_url path
    joiner = (path =~ /\?/) ? "&" : "?"
    "#{service.data.server_url}/rest/#{path}#{joiner}api_key=#{service.data.api_key}"
  end
end
