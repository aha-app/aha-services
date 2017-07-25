class P2PMResource < GenericResource

  API_VERSION = "1.0"

  def faraday_builder b
    if @service.class.service_name == "tfs_on_premise"
      b.request(:tfs_ntlm, self, @service.data.user_name, @service.data.user_password)
    else
      b.basic_auth(@service.data.user_name, @service.data.user_password)
    end
  end

  def self.default_http_options
    super
    @@default_http_options[:headers]["Content-Type"] = "application/json"
    @@default_http_options[:adapter] = :net_http_persistent
    @@default_http_options
  end

def process_RestClient_response(response, *success_codes, &block)
    success_codes = [200, 201] if success_codes == []
    if success_codes.include?(response.code)
      if block_given?
        yield hashie_or_array_of_hashies(response.body)
      else
        return hashie_or_array_of_hashies(response.body)
      end
    elsif response.code == 404
      msg = parse(response.body)
      raise AhaService::RemoteError, "Remote resource was not found: #{msg['message']}"
    elsif response.code == 400
      msg = parse(response.body)
      raise AhaService::RemoteError, "The request was not valid: #{msg['message']}"
    elsif [403, 401].include?(response.code)
      raise_config_error "The API key is invalid or has insufficent rights."
    else
      raise AhaService::RemoteError, "Unhandled error: STATUS=#{response.code} BODY=#{response.body}"
    end
  end

  def process_response(response, *success_codes, &block)
    success_codes = [200] if success_codes == []
    if success_codes.include?(response.status)
      if block_given?
        #yield hashie_or_array_of_hashies(response.body)
        yield response.body
      else
        #return hashie_or_array_of_hashies(response.body)
        return response.body
      end
    elsif response.status == 302
      raise_config_error "Authentication denied. Invalid credentials."
    elsif response.status == 404
      raise AhaService::RemoteError, "Remote resource was not found."
    elsif response.status == 400
      errors = parse(response.body)
      raise AhaService::RemoteError, errors["message"]
    elsif [403, 401].include?(response.status)
      raise_config_error "Credentials are invalid or have insufficent rights."
    else
      raise AhaService::RemoteError, "Unhandled error: STATUS=#{response.status} BODY=#{response.body}"
    end
  end
 
  def get_security_token
    body = {
      'grant_type' => "password",
      'scope' => "*",
      'client_id' => @service.data.client_id,
      'client_secret' => @service.data.client_secret,
      'username' => @service.data.user_name,
      'password' => @service.data.user_password
    }
    logger.debug "URL: #{@service.data.server_url}\n"
    logger.debug "Body: #{body}\n"
    response = RestClient.post @service.data.server_url, body.to_json, {content_type: :json, accept: :json} { |response, request, result, &block|
      case response.code
        when 200
          #p "It worked !"
          response
        when 423
          raise SomeCustomExceptionIfYouWant
        else
          response.return!(&block)
      end
    }
    #puts response
    parsed = JSON.parse(response)
    security_token = parsed['access_token']
    #logger.debug "PR access_token = #{security_token}"
    security_token
  end
  
  def create_attachments(workitem, aha_attachments)
    existing_files = workitem.relations.select{|relation| relation.rel == "AttachedFile"}.map{|relation| relation.attributes.name} rescue []
    aha_attachments.each do |aha_attachment|
      next if existing_files.include?(aha_attachment.file_name)
      new_attachment = attachment_resource.create aha_attachment
      if new_attachment
        workitem_resource.add_attachment workitem, new_attachment, aha_attachment.file_size.to_i
      end
    end
  rescue AhaService::RemoteError => e
    logger.error e.message
  end

protected
  def description_or_default(body)
    if body.present?
      body
    else
      "<p></p>"
    end
  end
 
  def mstfs_url path
    joiner = (path =~ /\?/) ? "&" : "?"
    "#{url_prefix}/_apis/#{path}#{joiner}api-version="+self.class::API_VERSION
  end

  def mstfs_project_url project, path
    joiner = (path =~ /\?/) ? "&" : "?"
    "#{url_prefix}/#{project}/_apis/#{path}#{joiner}api-version="+self.class::API_VERSION
  end
  
  def url_prefix
    if @service.class.service_name == "tfs_on_premise"
      @service.data.server_url
    else
      "https://#{@service.data.account_name}.visualstudio.com/defaultcollection"
    end
  end
  
end


class P2PMNtlm < Faraday::Middleware

  def initialize(app, service, username, password)
    super app
    @service = service
    @username = username
    @password = password
  end

  def call(env)
    response = handshake(env)
    return response unless response.status == 401

    env[:request_headers]['Authorization'] = header(response)
    @app.call(env)
  end
    
  def handshake(env)
    env_without_body = env.dup
    env_without_body[:request_headers] = env[:request_headers].dup
    env_without_body.clear_body
      
    ntlm_message_type1 = Net::NTLM::Message::Type1.new
    %w(workstation domain).each do |a|
      ntlm_message_type1.send("#{a}=",'')
      ntlm_message_type1.enable(a.to_sym)
    end
    
    env_without_body[:request_headers]['Authorization'] = 'NTLM ' + ntlm_message_type1.encode64
    
    @app.call(env_without_body)
  end
  
  def header(response)
    challenge = response.headers['www-authenticate'][/NTLM (.+)/, 1]
    
    ntlm_message = Net::NTLM::Message.decode64(challenge)
    
    'NTLM ' + ntlm_message.response({user: @username, password: @password, domain: ''}, {:ntlmv2 => true}).encode64
  end
end

Faraday::Request.register_middleware :p2pm_ntlm => lambda { P2PMNtlm }
