class AhaServices::SecurityWebhook < AhaService
  title "Security webhook"
  caption "HTTP webhook for security related activity"
  category "API"

  string :hook_url
  
  def receive_security
    http.headers['Content-Type'] = 'application/json'
    
    # We only allow 5 seconds for webhooks.
    Timeout.timeout(5, Timeout::Error) do
      http_post data.hook_url, payload.to_json
    end
  end
  
end
