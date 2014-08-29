class AhaServices::AuditWebhook < AhaService
  title "Activity webhook"
  caption "Generic HTTP webhook for all activity"

  string :hook_url
  
  def receive_audit
    http_post data.hook_url, payload.to_json
  end
  
end
