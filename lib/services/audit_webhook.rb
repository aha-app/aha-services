class AhaServices::AuditWebhook < AhaService
  title "Activity webhook"
  caption "Generic HTTP webhook for all activity"

  string :hook_url
  
  def receive_audit
    # We only allow 5 seconds for webhooks.
    Timeout.timeout(5, TimeoutError) do
      http_post data.hook_url, payload.to_json
    end
  end
  
end
