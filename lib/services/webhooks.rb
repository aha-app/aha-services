class AhaServices::Webhooks < AhaService
  string :hook_url
  
  def receive_event
    http_post data.hook_url, payload.to_json
  end
end
