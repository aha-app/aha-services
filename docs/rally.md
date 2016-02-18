This integration allows you to push features and requirements from Aha! to Rally online.

## Features

* One Aha! product is associated with one Rally project.
* A feature can be sent to the Rally server using the _Send to Rally_ item in the _Action_ menu on the features page.
* Requirements are sent to Rally together with the feature.
* Only the name, description and attachments of features and requirements are sent.
* Releases in Aha! will created releases in Rally.
* When requirements are sent to Rally they will be scheduled in the release that they belong to. 
* Changes in Rally will be immediately reflected in Aha! via the webhook. Aha! will automatically install the necessary webhook when the integration is configured.

## Configuration

You need to be Product Owner in Aha! to set up this integration.

Create the integration in Aha!

1. Enter your Rally username and password.
2. Click the _Test connection_ button.
3. On success, you should be able to choose one of your Rally projects that this Aha! product should integrate with. The list of projects that you see is controlled by the "Default Workspace" you have configured in your Rally user profile. If you are not seeing the projects you expect it is probably becasue your default workspace is not set.
4. Enable the integration.
5. Test the integration by going to one of your features in Aha! and using the _Send to Rally_ item in the _Actions_ menu on the features page. You should then look at your project in Rally and see that the feature (and any requirements) were properly converted to user stories. 

## Troubleshooting

To help you troubleshoot an error, we provide the detailed integration logs below. Contact us at support@aha.io if you need further help.
