class AhaServices::AuditWebhook < AhaService
  title "Activity webhook"
  caption "HTTP webhook for all record changes"
  category "API"

  string :hook_url
  
  audit_filter

  boolean :validate_cert,
    description: "Validate your server's HTTPS/TLS certificate",
    label_name: "Validate certificate"
  
  def receive_audit
    http.headers['Content-Type'] = 'application/json'
    
    # We only allow 5 seconds for webhooks.
    Timeout.timeout(5, Timeout::Error) do
      http_post data.hook_url, payload.to_json
    end
  end
  
  def validate_cert?
    data&.validate_cert == "1"
  end

end
