class AhaServices::AuditWebhook < AhaService
  title "Activity webhook"
  caption "HTTP webhook for all record changes"
  category "API"

  string :hook_url
  
  audit_filter
  
  def receive_audit
    http.headers['Content-Type'] = 'application/json'
    
    # We only allow 5 seconds for webhooks.
    Timeout.timeout(5, Timeout::Error) do
      http_post data.hook_url, payload.to_json
    end
  end
  
end
