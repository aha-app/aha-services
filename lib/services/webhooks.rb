class AhaServices::Webhooks < AhaService
  string :hook_url
  
  def receive_event
    logger.info("DATA: #{data.inspect}")
    logger.info("HOOK: #{data.hook_url}")
    http_post data.hook_url, payload.to_json
  end
end
