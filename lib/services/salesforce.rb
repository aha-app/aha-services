class AhaServices::Salesforce < AhaService
  caption do |workspace_type|
    object =
      case workspace_type
      when "multi_workspace" then "ideas or requests"
      when "product_workspace" then "ideas"
      when "marketing_workspace" then "requests"
      end
    "Receive #{object} from Salesforce"
  end
  category "Ideas capture"
  
  oauth2_button authorize_url: "https://login.salesforce.com/services/oauth2/authorize",
    token_url: "https://login.salesforce.com/services/oauth2/token",
    parameters: {display: "popup", immediate: "false"}
  
  string :host, description: "The custom host to use for sandbox Salesforce organizations. Leave this blank if you are not using a sandbox organization."
  
  internal :idea_portal_id
  
  install_button

  def receive_updated
    validate_host
  end

  def receive_installed
    validate_host or raise ConfigurationError, "Please ensure the custom host ends in salesforce.com and does not include http:// or https://."

    begin
      # Validate authentication.
      client.user_info
      
      # Update settings.
      client.post('/services/apexrest/ahaapp/aha_rest_api/settings', 
        idea_portal_url: data.idea_portal_url, 
        jwt_secret_key: data.jwt_secret_key)
    rescue Exception => e
      logger.debug("Salesforce authentication problem #{e.class}: #{e.message} #{e.backtrace.join("\n")}")
      if e.message.include? 'The REST API is not enabled for this Organization.'
        raise ConfigurationError, "The REST API is not enabled for this Organization."
      else
        raise ConfigurationError, "Authentication failed. Please use the 'Authenticate' button to connect to Salesforce."
      end
    end
  end
    
  def client
    if data.oauth2_token.present?
      @client ||= Restforce.new oauth_token: data.oauth2_token,
        refresh_token: data.oauth2_refresh_token,
        client_id: data.consumer_key,
        client_secret: data.consumer_secret,
        host: data.host.present? ? data.host : "login.salesforce.com"
    else
      @client ||= Restforce.new username: data.username,
        password: data.password,
        security_token: data.security_token,
        client_id: data.consumer_key,
        client_secret: data.consumer_secret,
        host: data.host.present? ? data.host : "login.salesforce.com"
    end
  end  
  
  def validate_host
    # Only do the validation if there is something in the host field
    return true if data["host"].blank?

    if data["host"] =~ /^https?:\/\//
      logger.error("Custom host should not include http:// or https://.")
      return false
    end

    if data["host"] && data["host"] !~ /salesforce.com$/
      logger.error("Custom host should end in salesforce.com.")
      return false
    end

    return true
  end
end
