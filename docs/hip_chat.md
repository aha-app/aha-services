Send a log of activity from Aha! to a HipChat room. Configure the integration for a product to send only activity for that product. Configure the integration for the account to send all activity that you have access to.

**WARNING** Sending activity out of Aha! and into HipChat bypasses the security controls in Aha!. Anyone who has access to your HipChat room will be able to see the activity, regardless of whether they have access to that information in Aha!

## Configuration

Configure a room in HipChat

1. In HipChat, go to the administration web interface. On the _Rooms_ screen choose the room you want Aha! activity to be sent to.
2. Go to the _Tokens_ sub-menu.
3. Create a new token and name it `Aha`.
4. Copy the value of the new token, you will need this in the Aha! configuration below.

Create the integration in Aha!

1. Enter the token from step 4 above into the _Auth token_ field.
2. Enter the name of the room from step 1 into the _Room name_ field. You must enter the room name exactly as it appears in HipChat.
3. Click the _Test connection_ button. After a short delay you should see a message appear in your HipChat client in the room you selected.
4. Enable the integration.
5. Consider renaming this integration with your HipChat room name for easy future reference. Perhaps something like: "HipChat: Customers." You can do this by clicking the _HipChat_ text in the heading of this page.

## Troubleshooting

To help you troubleshoot an error, we provide the detailed integration logs below. Contact us at support@aha.io if you need further help.