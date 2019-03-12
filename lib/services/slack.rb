class AhaServices::Slack < AhaService
  title "Slack [from Aha!]"
  caption do |workspace_type|
    subject =
      case workspace_type
      when "multi_workspace" then "product or workspace"
      when "product_workspace" then "product"
      when "marketing_workspace" then "workspace"
      end
    "Send #{subject} notifications from Aha! to Slack"
  end
  category "Communication"
  
  webhooks_slack_button
  install_button
  
  audit_filter
  
  def receive_installed
    send_message(text: "Aha! integration installed successfully. Make sure you enable the integration!")
  end
  
  def receive_audit
    audit = payload.audit
    return unless audit.interesting
    
    user = if audit.user
        audit.user.name
      else
        "Aha!"
      end
    
    link = if audit.auditable_url
        "<#{audit.auditable_url}|#{audit.description}>"
      else
        audit.description
      end
      
    send_message(
      username: "Aha!",
      icon_url: "https://secure.aha.io/assets/logos/aha_square_300.png",
      attachments: [
        fallback: "#{user} #{audit.description}",
        pretext: "*#{user}* #{link}",
        mrkdwn_in: ["pretext", "text", "fields"],
        fields: audit.changes.collect do |change|
          {
            title: change.field_name,
            value: html_to_slack_markdown(change.value),
            short: is_wide_field(change.field_name)
          }
        end
      ]
    )
  end
    
  
protected

  def is_wide_field(field_name)
    !["Description", "Theme", "Body"].include?(field_name)
  end

  def url
    data.url || data.webhook_url
  end

  def send_message(message)
    raise AhaService::RemoteError, "Integration has not been configured" unless url

    http.headers['Content-Type'] = 'application/json'
    response = http_post(url, message.to_json)
    if [200, 201, 204].include?(response.status)
      return
    elsif response.status == 404
      raise AhaService::RemoteError, "URL is not recognized"
    else
      error = Hashie::Mash.new(JSON.parse(response.body))
      
      raise AhaService::RemoteError, "Unhandled error: STATUS=#{response.status} BODY=#{error.message}"
    end
  end
  
end
