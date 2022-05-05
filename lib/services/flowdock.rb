class AhaServices::Flowdock < AhaService
  caption "Send workspace notifications from Aha! to Flowdock"
  category "Communication"

  string :flow_api_token,
    description: "The API token for the Flow you want to send Aha! activity to."
  install_button

  audit_filter

  def receive_installed
    send_message("Aha! integration installed successfully", nil,
      "Make sure you enable the integration!", "Aha!", "support@aha.io")
  end

  def receive_audit
    audit = payload.audit
    return unless audit.interesting

    user, email = if audit.user
        [audit.user.name, audit.user.email]
      else
        ["Aha!", "support@aha.io"]
      end

    fields = audit.changes.collect { |change| "<div><b>#{change.field_name}</b> #{change.value}</div>" }
    fields = ["[No change details]"] if fields.empty?
    send_message("#{user} #{audit.description}", audit.auditable_url, fields.join("\n"), user, email)
  end

protected

  def send_message(subject, link, content, user, email)
    message = {
      source: "Aha",
      from_address: email,
      from_name: user,
      subject: subject,
      content: content,
      link: link
    }
    http.headers['Content-Type'] = 'application/json'
    response = http_post("https://api.flowdock.com/v1/messages/team_inbox/#{URI::Parser.new.escape(data.flow_api_token)}",
      message.to_json)
    if [200, 201, 204].include?(response.status)
      return
    else
      raise AhaService::RemoteError, "Unhandled error: STATUS=#{response.status} BODY=#{response.body}"
    end
  end

end
