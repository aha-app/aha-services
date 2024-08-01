class AhaServices::SlackCommands < AhaService
  title "Aha! (from Slack)"
  caption "Send new ideas and work updates to Aha! from Slack"
  category "Communication"

  commands_slack_button

  def receive_installed
    send_message(text: "Aha! integration installed successfully. Make sure you enable the integration!")
  end
end
