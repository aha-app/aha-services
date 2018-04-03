class AhaServices::GoogleHangoutsChat < AhaService
  caption "Send customized activity from Aha! into group chat"
  category "Communication"
  
  string :google_hangouts_chat_webhook_url,
    description: "The webhook that you copied from the room"
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

    description = [user, audit.description].join(' ')
      
    kvs = audit.changes.map do |change|
      { keyValue: { topLabel: change["field_name"], content: change["value"] } }
    end
    send_message(
      cards: [
        {
          sections: [
            {
              widgets: [ { textParagraph: { text: description } } ]
            },
            {
              widgets: kvs
            },
            {
              widgets: [
                {
                  buttons: [
                    {
                      textButton: {
                        text: "GO TO OBJECT",
                        onClick: {
                          openLink: { url: audit.auditable_url }
                        }
                      }
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    )
  end
    
  
protected

  def is_wide_field(field_name)
    !["Description", "Theme", "Body"].include?(field_name)
  end

  def url
    data.google_hangouts_chat_webhook_url
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
