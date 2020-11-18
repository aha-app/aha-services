Send a log of activity from Aha! to a Microsoft Teams channel. Configure the integration for a workspace to send only activity for that workspace. Configure the integration for the account to send all activity that you have access to.

**WARNING** Sending activity out of Aha! and into Microsoft Teams bypasses the security controls in Aha!. Anyone who has access to your Microsoft Team will be able to see the activity, regardless of whether they have access to that information in Aha!

## Configuration

Create an incoming webhook in Microsoft Teams

1. Navigate to the channel where you want to add the webhook and select (**•••**) More Options from the top navigation bar. 
1. Choose **Connectors** from the drop-down menu and search for **Incoming Webhook**.
1. Select the **Configure** button, provide a name, and, optionally, upload an image avatar for your webhook.
1. The dialog window will present a unique URL that will map to the channel. Make sure that you **copy and save the URL**—you will need to provide it to the outside service.
1. Select the **Done** button. The webhook will be available in the team channel.


Create the integration in Aha! 

1. Enter the URL into the **Webhook URL** field.
1. Click the Test connection button. After a short delay you should see a message appear in the Microsoft Teams channel you copied the webhook from.
1. Customize the integration by selecting the activities which you would like to appear in your Microsoft Teams channel.
1. Enable the integration.
1. Consider renaming this integration with your Microsoft Teams channel name for easy future reference. Perhaps something like: "Microsoft Teams: #product." You can do this by clicking the Microsoft Teams text in the heading of this page.

## Troubleshooting

To help you troubleshoot an error, we provide the detailed integration logs below. Contact us at support@aha.io if you need further help.
