This integration allows you to push features and requirements from Aha! to Azure DevOps Server (Formerly Microsoft TFS 2015).

This integration works with the on-premise version of Azure DevOps Server. If you use Azure DevOps Services (formerly VSTS) then use the separate _Azure DevOps Services_ integration instead.

## Features

* Authentication with Azure DevOps Services is done using NTLM.
* One Aha! product is associated with one Azure DevOps Services project.
* A feature can be sent to the Azure DevOps server using the _Send to Azure DevOps Server_ item in the _Send_ dropdown next to the Integrations field on the features page.
* Requirements are sent with the feature.
* Only the name, description and attachments of features and requirements are sent.
* If you set up a subscription in Azure DevOps Server, the integration can receive updates about name changes, description changes or status changes.
* The mapping of Azure DevOps Server states to Aha! workflow statuses is configurable.

## Configuration

You need to be Product Owner in Aha! to set up this integration.

To configure this integration, first create the integration in Aha!

1. Enter the server URL of your Azure DevOps Server environment, including the collection name, but without a trailing slash.
2. Enter your username and password.
3. Click the _Test connection_ button.
4. On success, you should be able to choose which project to integrate with. You also must select an area of this project where features and requirements should be created.
5. Select the work item type to which features should be mapped. Then select for each Azure DevOps Server state to which Aha! workflow status it should be mapped.
6. Repeat step 5 for requirements.
7. Enable the integration and test it by going to one of your features in Aha! and using the _Send to Azure DevOps Server_ item in the _Send_ dropdown next to the Integrations field.
8. The feature should now appear in your Azure DevOps Server project together with its requirements.

If you want to be able to receive updates from Azure DevOps Server you must setup a subscription.

1. Copy the Webhook URL from the configuration page.
2. In your Azure DevOps Server account, go to the project you want to integrate with.
3. Click the small cog in the top right corner to go to the settings.
4. Click on the _Service Hooks_ tab.
5. Add a new service hook by clicking the green plus.
6. Choose the _Web Hooks_ service and click _Next_.
7. Choose the _Work item updated_ trigger from the dropdown menu. You can leave the filters unchanged and click _Next_.
8. In the _Action_ settings, paste the Webhook URL from Aha! into the _URL_ field.
9. Press _Finish_ to create the subscription.

## Troubleshooting

To help you troubleshoot an error, we provide the detailed integration logs below. Contact us at support@aha.io if you need further help.
