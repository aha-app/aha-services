class AhaServices::HipChat < AhaService
  title "HipChat"
  caption "Send customized activity from Aha! into group chat"
  
  string :auth_token,
    description: "An authentication token from HipChat. For best security you should use a 'Room Notification Token'."
  string :room_name, description: "The name or API ID of the room messages should be sent to."
  install_button
  
  audit_filter
  
  def receive_installed
    send_message("Aha! integration installed successfully. Make sure you enable the integration!")
  end
  
  def receive_audit
    audit = payload.audit
    return unless audit.interesting
    
    user = if audit.user
        audit.user.name
      else
        "Aha!"
      end

    fields = audit.changes.collect { |change| "<b>#{change.field_name}</b> #{html_to_hipchat_markdown(change.value)}<br/>" }
    link = if audit.auditable_url
        "<a href='#{audit.auditable_url}'>#{audit.description}</a>"
      else
        audit.description
      end
      
    send_message <<-EOS
      #{user} #{link}<br/>
      #{fields.join("\n")}
    EOS
  end
    
protected

  def send_message(message)
    http.headers['Content-Type'] = 'application/json'
    response = http_post("https://api.hipchat.com/v2/room/#{URI::encode(data.room_name)}/notification?auth_token=#{data.auth_token}", 
      {message: message, message_format: 'html'}.to_json)
    if [200, 201, 204].include?(response.status)
      return
    elsif response.status == 404
      raise AhaService::RemoteError, "Room is not recognized"
    else
      error = Hashie::Mash.new(JSON.parse(response.body))
      
      raise AhaService::RemoteError, "Unhandled error: STATUS=#{response.status} BODY=#{error.message}"
    end
  end
  
end
