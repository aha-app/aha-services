class AhaServices::Webhooks < AhaService
  title "Integration webhook"
  caption "Generic HTTP webhook for feature integration"
  category "API"

  string :hook_url
  boolean :validate_cert,
    description: "Validate your server's HTTPS/TLS certificate",
    label_name: "Validate certificate"

  def receive_create_feature
    http.headers['Content-Type'] = 'application/json'
    
    http_post data.hook_url, payload.to_json
  end
  
  def receive_update_feature
    http.headers['Content-Type'] = 'application/json'
    
    http_post data.hook_url, payload.to_json
  end

  def receive_create_release
    http.headers['Content-Type'] = 'application/json'
    
    http_post data.hook_url, payload.to_json
  end
  
  def receive_update_release
    http.headers['Content-Type'] = 'application/json'
    
    http_post data.hook_url, payload.to_json
  end

  def validate_cert?
    data&.validate_cert == "1"
  end
  
end
