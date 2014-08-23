Send a log of activity from Aha! to a Slack channel. Configure the integration for a product to send only activity for that product. Configure the integration for the account to send all activity that you have access to.

**WARNING** Sending activity out of Aha! and into Slack bypasses the security controls in Aha!. Anyone who has access to your Slack channel will be able to see the activity, regardless of whether they have access to that information in Aha!

## Configuration

Configure integration in Slack

1. In Slack, go to the integrations section of the account configuration.
2. Create a new `Incoming WebHooks` integration.
3. Choose or create a channel for the Aha! activity to be sent to.
4. Copy the value of the `Your Unique Webhook URL` field.

Create the integration in Aha!

1. Enter the URL from step 4 above in the _Webhook url_ field.
3. Click the _Test connection_ button. After a short delay you should see a message appear in your Slack client in the channel you selected.
4. Enable the integration.

## Troubleshooting

To help you troubleshoot an error, we provide the detailed integration logs below. Contact us at support@aha.io if you need further help.