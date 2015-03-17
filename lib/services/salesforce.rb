class AhaServices::Salesforce < AhaService
  caption "Receive ideas from Salesforce"
  
  string :username, description: "This is the email address you use to login to Salesforce."
  password :password
  password :security_token, description: "Your Salesforce security token. You can request a new token in Salesforce under your name -> \"My Settings\" -> \"Personal\" -> \"Reset My Security Token\"."  
  string :host, description: "The custom host to use for sandbox Salesforce organizations. Leave this blank if you are not using a sandbox org."
  
  install_button

  def receive_installed
    client.user_info
  rescue Exception => e
    logger.debug("Salesforce authentication problem #{e.message} #{e.backtrace.join("\n")}")
    raise ConfigurationError, "Unable to authenticate"
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