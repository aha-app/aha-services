class AhaServices::GoogleHangoutsChat < AhaService
  caption "Send workspace notifications from Aha! to Google Hangouts Chat"
  category "Communication"
  
  string :webhook_url,
    description: "The URL that you copied when creating the webhook in Google Hangouts Chat"
  install_button
  
  audit_filter
  
  def receive_installed
    send_message(text: "Aha! integration installed successfully. Make sure you enable the integration!")
  end
  
  def receive_audit
    return unless payload.audit.interesting
    
    update_section = {
      widgets: update_kvs
    }

    sections = update_kvs.empty? ? [title_section, link_section] : [title_section, update_section, link_section]
    message = { cards: [ { sections: sections } ] }
    send_message(message)
  end
  
protected

  def title_section
    user = payload.audit.user&.name || "Aha!"

    description = "<b>#{user}</b> #{payload.audit.description}"
      
    { widgets: [ { textParagraph: { text: description } } ] }
  end

  def update_kvs
    @update_kvs ||= payload.audit.changes.map do |change|
      content = html_change_colors(change["value"])
      { keyValue: { topLabel: change["field_name"], content: content, contentMultiline: "true" } }
    end
  end

  def link_section
    {
      widgets: [
        {
          buttons: [
            {
              textButton: {
                text: "VIEW IN AHA!",
                onClick: {
                  openLink: { url: payload.audit.auditable_url }
                }
              }
            }
          ]
        }
      ]
    }
  end

  def html_change_colors(val)
    frag = Nokogiri::HTML.fragment(val.to_s)
    frag.css('.deleted').each { |el| el.name= "font"; el.set_attribute("color" , "#9d261d") } # modifies frag in place
    frag.css('.inserted').each { |el| el.name= "font"; el.set_attribute("color" , "#46a546") } # modifies frag in place
    frag.to_html
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
    elsif response.status == 404
      raise AhaService::RemoteError, "URL is not recognized"
    else
      error = Hashie::Mash.new(JSON.parse(response.body))
      
      raise AhaService::RemoteError, "Unhandled error: STATUS=#{response.status} BODY=#{error.message}"
    end
  end
  
end
