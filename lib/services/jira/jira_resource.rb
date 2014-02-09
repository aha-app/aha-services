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

  def process_response(response, *success_codes, &block)
    if success_codes.include?(response.status)
      yield parse(response.body) if block_given?
    elsif response.status == 401 || response.status == 403
      raise AhaService::RemoteError, "Authentication failed: #{response.status} #{response.headers['X-Authentication-Denied-Reason']}"
    elsif response.status == 400
      errors = parse(response.body)
      error_string = errors["errorMessages"].join(", ") +
        errors["errors"].map {|k, v| "#{k}: #{v}" }.join(", ")
      raise AhaService::RemoteError, "Data not accepted: #{error_string}"
    else
      raise AhaService::RemoteError, "Unhandled error: STATUS=#{response.status} BODY=#{response.body}"
    end
  end

  def faraday_builder(builder)
    if jira_connect_resource?
      builder.request :add_jira_user, @service.data.user_id
      builder.request :oauth, consumer_key: @service.data.consumer_key,
        consumer_secret: @service.data.consumer_secret, signature_method: "RSA-SHA1"
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
    uri.query = [uri.query, "user_id=#{@user_id}"].compact.join('&')

    @app.call(env)
  end
end

Faraday.register_middleware :request, :add_jira_user => lambda { AddJiraUser }
