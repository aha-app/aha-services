class JiraResource < GenericResource

  def prepare_request
    super
    auth_header
  end

  def auth_header
    # No auth in JiraConnect - we are doing it with middleware.
    unless jira_connect_resource?
      http.basic_auth @service.data.username, @service.data.password
    end
  end

  def better_error_messages value
    case value.strip
    when "Option id 'null' is not valid"
      "The value sent from Aha! ('#{value}') did not match any options for the JIRA Field. Are you sure the options are identical?"
    when /Option value '([^']*)' is not valid/, /Option id '([^']*)' is not valid/
      "The value sent from Aha! ('#{$1}') did not match any options for the JIRA Field. Are you sure the options are identical?"
    else
      value
    end
  end

  def error_message_for_field k, v
    field_name = @service.meta_data.fields[k]["name"] rescue k
    "'#{field_name}': #{better_error_messages(v)}"
  end

  def process_response(response, *success_codes, &block)
    if success_codes.include?(response.status)
      yield hashie_or_array_of_hashies(response.body) if block_given?
    elsif response.status == 401 || response.status == 403
      raise AhaService::RemoteError, "Authentication failed: #{response.status} #{response.headers['X-Authentication-Denied-Reason']}"
    elsif response.status == 400
      errors = parse(response.body)
      error_string = errors["errorMessages"].join(", ") +
        errors["errors"].map {|k, v| error_message_for_field(k,v) }.join(", ")
      raise AhaService::RemoteError, "Data not accepted: #{error_string}"
    else
      raise AhaService::RemoteError, "Unhandled error: STATUS=#{response.status} BODY=#{response.body}"
    end
  end

  def faraday_builder(builder)
    if jira_connect_resource?
      builder.request :add_jira_user, @service.data.user_id
      if @service.data.shared_secret
        builder.request :add_jira_jwt,  @service.data.client_key, 
          @service.data.shared_secret, @service.data.server_url
      else
        builder.request :oauth, consumer_key: @service.data.consumer_key,
          consumer_secret: @service.data.consumer_secret, signature_method: "RSA-SHA1"
      end
    else
      super
    end
  end

protected

  def api_url
    "#{@service.data.server_url}/rest/api/2"
  end

  def jira_connect_resource?
    @service.data.user_id
  end

end

class AddJiraUser < Faraday::Middleware

  def initialize(app, user_id)
    @app = app
    @user_id = user_id
  end

  def call(env)
    uri = env[:url]
    uri.query = [uri.query, "user_id=#{URI.escape(@user_id)}"].compact.join('&')

    @app.call(env)
  end
end

class AddJiraJwt < Faraday::Middleware
  
  def initialize(app, client_key, shared_secret, context_url)
    @app = app
    @client_key, @shared_secret, @context_url = client_key, shared_secret, context_url
  end

  def call(env)
    uri = env[:url]
    
    canonical_url = canonical_url(env[:method].to_s.upcase, uri)
    qsh = Digest::SHA256.new.hexdigest(canonical_url)
    
    jwt = JWT.encode({"iss" => "io.aha.connect", "iat" => Time.now.utc.to_i, 
      "exp" => Time.now.utc.to_i + 300, "qsh" => qsh}, @shared_secret, "HS256")
    
    uri.query = [uri.query, "jwt=#{jwt}"].compact.join('&')

    @app.call(env)
  end
  
  def path_without_context(path)
    context_path = URI.parse(@context_url).path
    new_path = path.sub(context_path, "")
    new_path = "/" if new_path.blank?
    new_path
  end
  
  def canonical_url(method, uri)
    [method, path_without_context(uri.path), normalized_params(Rack::Utils.parse_query(uri.query))].join('&')
  end

  def normalized_params(params)
    params.map{|p| p.map{|v| escape(v) } }.sort.map{|p| p.join('=') }.join('&')
  end
  
  def escape(value)
    URI.escape(value.to_s, /[^a-z0-9\-\.\_\~]/i)
  end
end

Faraday::Request.register_middleware :add_jira_user => lambda { AddJiraUser }
Faraday::Request.register_middleware :add_jira_jwt => lambda { AddJiraJwt }
