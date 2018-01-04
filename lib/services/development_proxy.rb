class AhaServices::DevelopmentProxy < AhaService
  caption "Developing new integrations"
  category "API"
  
  string :proxy_server_url, description: "URL of the proxy server to send all requests to."
  internal :development_form
  
  # Development code responds to all events.
  def self.responds_to_event(event)
    true
  end
  
end