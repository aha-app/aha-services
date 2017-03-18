class AhaServices::Salesforce < AhaService
  caption "Receive ideas from Salesforce"
  
  oauth2_button authorize_url: "https://login.salesforce.com/services/oauth2/authorize",
    token_url: "https://login.salesforce.com/services/oauth2/token",
    parameters: "display=popup&immediate=false"
  
  # TODO: old params - remove
  #string :username, description: "This is the email address you use to login to Salesforce."
  #password :password
  #password :security_token, description: "Your Salesforce security token. You can request a new token in Salesforce under your name -> \"My Settings\" -> \"Personal\" -> \"Reset My Security Token\"."  
  
  string :host, description: "The custom host to use for sandbox Salesforce organizations. Leave this blank if you are not using a sandbox organization."
  
  install_button

  def receive_installed
    client.user_info
  rescue Exception => e
    logger.debug("Salesforce authentication problem #{e.class}: #{e.message} #{e.backtrace.join("\n")}")
    if e.message.include? 'The REST API is not enabled for this Organization.'
      raise ConfigurationError, "The REST API is not enabled for this Organization."
    else
      raise ConfigurationError, "Authentication failed. Please verify the settings are correct."
    end
  end
    
  def client
    @client ||= Restforce.new username: data.username,
      password: data.password,
      security_token: data.security_token,
      client_id: data.consumer_key,
      client_secret: data.consumer_secret,
      host: data.host.present? ? data.host : "login.salesforce.com"
  end  
  
end