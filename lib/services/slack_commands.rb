class AhaServices::SlackCommands < AhaService
  title "Slack - Create Records"
  caption "Create new records directly from Slack using the /aha command."
  category "Communication"

  commands_slack_button

  def receive_installed
    send_message(text: "Aha! integration installed successfully. Make sure you enable the integration!")
  end
end
