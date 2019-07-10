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

  def error_message_for_field key, value
    jira_field_name = @service.meta_data.fields[key]["name"] rescue key
    field_info = @service.data.field_mapping.grep(Hash).detect{|m| m["jira_field"] == key }
    if field_info
      aha_field_name = field_info["aha_field"]
    else
      aha_field_name = "None"
    end
    
    case value.strip
    when "Option id 'null' is not valid"
      "The value sent from the Aha! field '#{aha_field_name}' did not match any options for the JIRA Field '#{jira_field_name}'. Are you sure the options are identical?"
    when /Option value '([^']*)' is not valid/, /Option id '([^']*)' is not valid/
      "The value sent from the Aha! field '#{aha_field_name}' ('#{$1}') did not match any options for the JIRA Field '#{jira_field_name}'. Are you sure the options are identical?"
    else
      "'#{key}': #{value}"
    end
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
      if @service.data.shared_secret
        builder.request :add_jira_jwt, @service.data.shared_secret,
          @service.data.user_id, @service.data.atlassian_account_id,
          @service.data.server_url
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
    @service.data.atlassian_account_id || @service.data.user_id
  end

end

class AddJiraJwt < Faraday::Middleware
  def initialize(app, shared_secret, user_id, atlassian_account_id, context_url)
    @app = app
    @shared_secret = shared_secret
    @user_id = user_id
    @atlassian_account_id = atlassian_account_id
    @context_url = context_url
  end

  def call(env)
    uri = env[:url]

    canonical_url = canonical_url(env[:method].to_s.upcase, uri)
    qsh = Digest::SHA256.new.hexdigest(canonical_url)

    claims = {
      'iss' => 'io.aha.connect',
      'iat' => Time.now.utc.to_i,
      'exp' => Time.now.utc.to_i + 300,
      'qsh' => qsh
    }
    claims.merge!(sub_claim) if sub_claim

    jwt = JWT.encode(claims, @shared_secret, 'HS256')

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

  def sub_claim
    @sub_claim ||= if @atlassian_account_id.present?
      { 'sub' => "urn:atlassian:connect:useraccountid:#{@atlassian_account_id}" }
    elsif @user_id.present?
      { 'sub' => "urn:atlassian:connect:userkey:#{@user_id}" }
    end
  end
end

Faraday::Request.register_middleware :add_jira_jwt => lambda { AddJiraJwt }
