This integration allows you to push features and requirements from Aha! to Rally online.

## Features

* One Aha! product is associated with one Rally project.
* A feature can be sent to the Rally server using the _Send to Rally_ item in the _Send_ dropdown next to the integrations field on the features page.
* Requirements are sent to Rally together with the feature.
* The name, description and attachments of features and requirements are sent. If a feature has a start and due date these will be sent to Rally portfolio items.
* Releases in Aha! will create releases in Rally.
* When requirements are sent to Rally they will be scheduled in the release that they belong to. 
* Changes in Rally will be immediately reflected in Aha! via the webhook. Aha! will automatically install the necessary webhook when the integration is configured.

## Configuration

You need to be Product Owner in Aha! to set up this integration.

Create the integration in Aha!

1. Enter your Rally username and password.
2. Click the _Test connection_ button.
3. On success you will be able to choose a Rally workspace. After choosing the workspace, click the _Test connection_ button again to populate the list of projects in that workspace.
4. Choose the project to integrate with. 
5. Based on the project you will be able to choose the mapping between Aha! and Rally resources.
6. Enable the integration.
7. Test the integration by going to one of your features in Aha! and using the _Send to Rally_ item in the _Send_ dropdown next to the integrations field on the features page. You should then look at your project in Rally and see that the feature (and any requirements) were properly converted to user stories.

## Troubleshooting

To help you troubleshoot an error, we provide the detailed integration logs below. Contact us at support@aha.io if you need further help.
