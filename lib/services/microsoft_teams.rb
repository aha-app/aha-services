class AhaServices::MicrosoftTeams < AhaService
  caption do |workspace_type|
    subject =
      case workspace_type
      when "multi_workspace" then "product or workspace"
      when "product_workspace" then "product"
      when "marketing_workspace" then "workspace"
      end
    "Send #{subject} notifications from Aha! to Microsoft Teams"
  end
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
    
    # array of elements with {"name": "asdf", "value": "the change"}
    facts = payload.audit.changes.each do |obj|
      obj["name"] = obj.delete("field_name")
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
    send_message(message)
  end
  
protected

  def title
    user = payload.audit.user&.name || "Aha!"

    "#{user} #{payload.audit.description}"
  end

  def url
    data.webhook_url
  end

  def send_message(message)
    raise AhaService::RemoteError, "Integration has not been configured" unless url

    http.headers['Content-Type'] = 'application/json'
    response = http_post(url, message.to_json)
    if [200, 201, 204].include?(response.status)
      return
    elsif response.body == 'Webhook Bad Request - Null or empty event'
      raise AhaService::RemoteError, "Please use the Microsoft Teams Webhook connector (not the Aha! connector) for this integration."
    elsif response.status == 404
      raise AhaService::RemoteError, "URL is not recognized"
    else
      error = Hashie::Mash.new(JSON.parse(response.body))
      
      raise AhaService::RemoteError, "Unhandled error: STATUS=#{response.status} BODY=#{error.message}"
    end
  end
  
end
