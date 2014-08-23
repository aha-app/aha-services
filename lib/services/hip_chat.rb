class AhaServices::HipChat < AhaService
  caption "Send all activity into a group chat for teams"
  
  string :auth_token,
    description: "An authentication token from HipChat. For best security you should use a 'Room Notification Token'."
  string :room_name, description: "The name or API ID of the room messages should be sent to."
  install_button
  
  def receive_installed
    send_message("Test message from <a href='http://www.aha.io/'>Aha!</a>")
  end
  
  def receive_audit
    audit = payload.audit
    user = if audit.user
        audit.user.name
      else
        "Aha!"
      end

    fields = audit.changes.collect { |change| "<b>#{change.field_name}</b> #{change.value}<br/>" }
    
    send_message <<-EOS
      #{user} <a href="#{audit.auditable_url}">#{audit.description}</a><br/>
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
