class AhaServices::MicrosoftTeams < AhaService
  caption "Send workspace notifications from Aha! to Microsoft Teams"
  category "Communication"

  string :webhook_url,
    description: "The URL that you copied when creating the webhook in Microsoft Teams"
  install_button

  audit_filter

  def receive_installed
    send_message(text: "Aha! integration installed successfully. Make sure you enable the integration!")
  end

  def receive_audit
    return unless payload.audit.interesting


    message = workflow_webhook? ? workflow_message : connector_message

    send_message(message)
  end

  def send_message(message)
    raise AhaService::RemoteError, "Integration has not been configured" unless url

    http.headers['Content-Type'] = 'application/json'
    response = http_post(url, message.to_json)
    if [200, 201, 202, 204].include?(response.status)
      return
    elsif response.body == 'Webhook Bad Request - Null or empty event'
      raise AhaService::RemoteError, "Please use the Microsoft Teams Webhook connector (not the Aha! connector) for this integration."
    elsif response.body == "Connector configuration not found"
      raise AhaService::RemoteError, "The connector configuration was not found"
    elsif response.status == 404
      raise AhaService::RemoteError, "URL is not recognized"
    else
      body_message =
        begin
          error = Hashie::Mash.new(JSON.parse(response.body))
          error.message
        rescue
          response.body
        end

      raise AhaService::RemoteError, "Unhandled error: STATUS=#{response.status} BODY=#{body_message}"
    end
  end

  protected

  def workflow_webhook?
    false
  end

  def connector_message
    message = {
      "@type": "MessageCard",
      "@context": "http://schema.org/extensions",
      "themeColor": "0073CF",
      "Summary": title,
      "sections": [{
          "activityTitle": title,
          "activitySubtitle": payload.audit.created_at.to_time.strftime('%Y-%m-%d %l:%M %P'),
          "facts": facts,
          "markdown": true
      }],
      "potentialAction": [
        {
          "@type": "OpenUri",
          "name": "View in Aha!",
          "targets": [
            {
              "os": "default",
              "uri": payload.audit.auditable_url
            }
          ]
        }
      ]
    }
  end

  def workflow_message
    {
      "type": "message",
      "body": {
        "attachments": [
          {
            "contentType": "application/vnd.microsoft.card.adaptive",
            "contentUrl": null,
            "content": {
              "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
              "type": "AdaptiveCard",
              "version": "1.2",
              "body": [
                {
                  "type": "TextBlock",
                  "text": "John Bohn updated feature A-1732 Partner leaderboards",
                  "weight": "bolder",
                  "size": "medium",
                  "wrap": true,
                  "style": "heading"
                },
                {
                  "type": "TextBlock",
                  "text": "2024-01-01 9:03pm",
                  "weight": "lighter",
                  "size": "small",
                  "wrap": true
                },
                {
                  "type": "FactSet",
                  "facts": facts
              }
              ],
              "actions": [
                {
                  "type": "Action.OpenUrl",
                  "title": "View in Aha!",
                  "url": "https://www.aha.io/features"
                }
              ]
            }
          }
        ]
      }
    }
  end


  def title
    user = payload.audit.user&.name || "Aha!"

    "#{user} #{payload.audit.description}"
  end

  def url
    data.webhook_url
  end

  # Array of elements with {"name|title": "asdf", "value": "the change"}
  def facts
    title_key = workflow_webhook? ? "title" : "name"

    payload.audit.changes.each do |obj|
      obj[title_key] = obj.delete("field_name")
      # convert textual fields to markdown that Microsoft can display
      if obj["value"].to_s.include?("</span>")
        old_val = obj["value"]
        parsed = Nokogiri::HTML::fragment(obj["value"])

        # remove existing styles to make modification styles more clear
        parsed.css('b,strong').each do |node|
          node.replace Nokogiri::XML::Text.new(node.text, node.document)
        end
        parsed.css('strike').each do |node|
          node.replace Nokogiri::XML::Text.new(node.text, node.document)
        end

        parsed.css('span.deleted').each { |node| node.name = 'strike' }
        parsed.css('span.inserted').each { |node| node.name = 'strong' }
        obj["value"] = parsed.to_s
      end
    end
  end
end
