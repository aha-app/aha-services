class AhaServices::DevelopmentProxy < AhaService
  
  string :proxy_server_url, description: "URL of the proxy server to send all requests to."
  development_form
  
end