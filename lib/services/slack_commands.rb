class AhaServices::SlackCommands < AhaService
  title "Slack [to Aha!]"
  caption do |workspace_type|
    object =
      case workspace_type
      when "multi_workspace" then "ideas or requests and features or activities"
      when "product_workspace" then "ideas and features"
      when "marketing_workspace" then "requests and activities"
      end
    "Send new #{object} to Aha! from Slack"
  end
  category "Communication"

  commands_slack_button

  def receive_installed
    send_message(text: "Aha! integration installed successfully. Make sure you enable the integration!")
  end
end
