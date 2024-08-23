class AhaServices::MicrosoftTeams < AhaService
  caption "Send workspace notifications from Aha! to Microsoft Teams"
  category "Communication"

  string :webhook_url,
    description: "The URL that you copied when creating the webhook in Microsoft Teams"

  select :integration_method, collection: [
      ["Use connector", "connector"],
      ["Use workflow", "workflow"]
  ], description: "Select your integration method. Microsoft is retiring Office 365 connectors in Microsoft Teams. While existing connectors will work until December 2025 with some required updates, no new connectors can be created after August 15, 2024. For long-term support and enhanced functionality, we recommend using workflows."

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
    data.integration_method == "workflow"
  end

  def connector_message
    message = {
      "@type": "MessageCard",
      "@context": "http://schema.org/extensions",
      "themeColor": "0073CF",
      "Summary": title,
      "sections": [{
          "activityTitle": title,
          "activitySubtitle": audit_time,
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
            "contentUrl": nil,
            "content": {
              "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
              "type": "AdaptiveCard",
              "version": "1.2",
              "body": [
                {
                  "type": "TextBlock",
                  "text": title,
                  "weight": "bolder",
                  "size": "medium",
                  "wrap": true,
                  "style": "heading"
                },
                {
                  "type": "TextBlock",
                  "text": audit_time,
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
                  "url": auditable_url
                }
              ]
            }
          }
        ]
      }
    }
  end

  def audit_time
    payload.audit.created_at.to_time.strftime('%Y-%m-%d %l:%M %P')
  end

  def auditable_url
    payload.audit.auditable_url
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
