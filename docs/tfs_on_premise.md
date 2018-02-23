This integration allows you to push features and requirements from Aha! to Microsoft Team Foundation Server 2015 (TFS).

This integration works with the on-premise version of TFS. If you use Visual Studio Team Services then use the separate _Visual Studio Team Services_ integration instead.

## Features

* Authentication with TFS is done using NTLM.
* One Aha! product is associated with one TFS project.
* A feature can be sent to the TFS server using the _Send to Team Foundation Server_ item in the _Send_ dropdown next to the integrations field on the features page.
* Requirements are sent to TFS together with the feature.
* Only the name, description and attachments of features and requirements are sent.
* If you set up a subscription in TFS the integration can receive updates about name changes, description changes or status changes.
* The mapping of TFS states to Aha! workflow statuses is configurable.

## Configuration

You need to be Product Owner in Aha! to set up this integration.

To configure this integration, first create the integration in Aha!

1. Enter the URL of your TFS server, including the collection name, but without a trailing slash.
2. Enter your TFS username and password.
3. Click the _Test connection_ button.
4. On success, you should be able to choose which project to integrate with. You also must select an area of this project where features and requirements should be created.
5. Select the workitemtype to which features should be mapped. Then select for each TFS state to which Aha! workflow status it should be mapped.
6. Repeat step 5 for requirements.
7. Enable the integration and test it by going to one of your features in Aha! and using the _Send to Team Foundation Server_ item in the _Send_ dropdown next to the integrations field.
8. The feature should now appear in your TFS project together with its requirements.

If you want to be able to receive updates from TFS you must setup a subscription.

1. Copy the Webhook URL from the configuration page.
2. In your TFS account, go to the project you want to integrate with.
3. Click the small cog in the top right corner to go to the settings.
4. Click on the _Service Hooks_ tab.
5. Add a new service hook by clicking the green plus.
6. Choose the _Web Hooks_ service and click _Next_.
7. Choose the _Work item updated_ trigger from the dropdown menu. You can leave the filters unchanged and click _Next_.
8. In the _Action_ settings, paste the Webhook URL from Aha! into the _URL_ field.
9. Press _Finish_ to create the subscription.

## Troubleshooting

To help you troubleshoot an error, we provide the detailed integration logs below. Contact us at support@aha.io if you need further help.
