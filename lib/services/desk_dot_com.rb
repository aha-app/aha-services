require 'desk_api'

class AhaServices::DeskDotCom < AhaService
  title "Desk.com"
  caption "Receive ideas from a Desk.com helpdesk"

  internal :idea_portal_id

  boolean :use_customer_name,
    description: "Use the customer name and email instead of the agents when creating a ticket"

  string :oauth_host,
    label: "Desk Host",
    description: "Your Desk.com domain. For example: mydeskdomain.desk.com."

  oauth_button request_token_path: "/oauth/request_token",
    access_token_path: "/oauth/access_token",
    authorize_path: "/oauth/authorize",
    parameters: "name=Aha!%20Integration&scope=read,write&expiration=never",
    callback_token_type: :access_token

  install_button hide_fetch_message: true, label: "Create Integration URL"

  internal :aha_integration_url

  string :shared_key, description: "Your Desk.com shared key"

  INTEGRATION_URL_NAME = "Aha!"

  # TODO When we convert to integrations 2, add a field to be able to change
  # the callback user just like we have on the callback_url field

  def receive_installed
    unless find_canvas_integration_url
      begin
        # Warning, you will likely get a validation error in development here
        # because of the http instead of https in the integration url.
        response = client.integration_urls.create(
          name: INTEGRATION_URL_NAME,
          description: "Allows easy linking of cases to Aha ideas",
          enabled: true,
          markup: data.integration_url,
          open_location: 'iframe_canvas')
      rescue DeskApi::Error::InternalServerError => e
        raise AhaService::RemoteError, "Integration has not been configured"
        logger.error("There was an error creating the integration. You may not be allowed to create any more integration URLs.")
        return false
      end
    end

    return true
  end

  def receive_updated
    return true
  end

  private

  # Find the Canvas Integration URL in the Desk.com with the Aha name
  def find_canvas_integration_url
    response = client.integration_urls

    loop do
      response.entries.each do |integration_url|
        return integration_url if integration_url.name == INTEGRATION_URL_NAME
      end

      # Get the next page if it exists
      response = response.next

      break unless response
    end

    return nil
  end

  def client
    host = data.oauth_host
    host = "https://#{host}" unless host.match("^https?://")

    DeskApi::Client.new({
      token: data.oauth_token,
      token_secret: data.oauth_secret,
      consumer_secret: data.consumer_secret,
      consumer_key: data.consumer_key,
      endpoint: host
    })
  end
end
