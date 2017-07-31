class AhaServices::DeskDotCom < AhaService
  title "Desk.com"
  caption "Receive ideas from a Desk.com helpdesk"

  # oauth_button request_token_url: "https://ahatest123.desk.com/oauth/request_token",
  #   access_token_url: "https://ahatest123.desk.com/oauth/access_token",
  #   authorize_url: "https://ahatest123.desk.com/oauth/authorize",
  #   parameters: "name=Aha!%20Integration&scope=read,write&expiration=never"

  string :desk_api_key,
    label: "API Key",
    description: "Your Desk.com API key"
  string :desk_api_secret,
    label: "API Secret",
    description: "Your Desk.com API secret"
  string :desk_token,
    label: "API Token",
    description: "Your Desk.com API access token"
  string :desk_token_secret,
    label: "API Token Secret",
    description: "Your Desk.com API access token secret"

  # install_button

  string :shared_key, description: "Your Desk.com shared key"

  internal :idea_portal_id

  boolean :use_customer_name,
    description: "Use the customer name and email instead of the agents when creating a ticket"

  # TODO When we convert to integrations 2, add a field to be able to change
  # the callback user just like we have on the callback_url field

  def receive_updated
    return true
  end
end
