This integration allows you to push features and requirements from Aha! to Azure DevOps Services (formerly VSTS.)

This integration works with the online version of Azure DevOps Services. If you run Azure DevOps Server (formerly Team Foundation Server) on-premise then use the separate _Azure DevOps Server_ integration instead.

## Features

* One Aha! product is associated with one Azure DevOps Services project.
* A feature can be sent to Azure DevOps Services using the _Send to Azure DevOps Services_ item in the _Send_ dropdown next to the Integrations field on the features page.
* Requirements are sent together with the feature.
* Only the name, description and attachments of features and requirements are sent.
* If you set up a subscription in Azure DevOps Services, the integration can receive updates about name changes, description changes or status changes.
* The mapping of Azure DevOps Services states to Aha! workflow statuses is configurable.

## Configuration

You need to be Product Owner in Aha! to set up this integration.

To configure this integration, first configure your Azure DevOps Services Services account.

1. Open your account dropdown (usually identified by your first initial or profile image) in the top right of the page and choose the _Security_.
2. Select _Personal access tokens_.
3. Add a new access token with scopes: Project and team (read), Work items (read and write).
4. Save the token value which is generated.

Next create the integration in Aha!

1. Enter the account name of your Azure DevOps Services account. It is equal to the subdomain of your Azure DevOps Services account.
2. Enter the personal access token you created in Azure DevOps Services.
3. Click the _Test connection_ button.
4. On success, you should be able to choose a project from Azure DevOps Services. You also must select an area of this project where features and requirements should be created.
5. Select the work item type to which features should be mapped. Then select for each Azure DevOps Services state to which Aha! workflow status it should be mapped.
6. Repeat step 5 for requirements.
7. Enable the integration and test it by going to one of your features in Aha! and using the _Send to Azure DevOps Services_ item in the _Send_ dropdown next to the Integrations field on the features page.
8. The feature should now appear in your Azure DevOps Services project together with its requirements.

If you want to be able to receive updates from Azure DevOps Services you must setup a subscription.

1. Copy the Webhook URL from the configuration page.
2. In your Azure DevOps Services account, go to the project you want to integrate with.
3. Click the small cog in the top center of the main navigation menu and click on the _Service Hooks_ option.
4. Add a new service hook by clicking the _+ Create subscription_ button.
5. Scroll to the option for the Web Hooks service and click Next.
6. Under _Trigger on this type of event_ choose the Work item updated trigger from the dropdown menu. To reduce unnecessary webhooks, add filters for the specific area, item type, or tags that you plan to integrate with Aha!. Click _Next_.
7. In the _Action > Settings_, paste the Webhook URL from Aha! into the _URL_ field. You can leave the option fields unchanged and click _Finish_ to create the subscription.

## Troubleshooting

To help you troubleshoot an error, we provide the detailed integration logs below. Contact us at support@aha.io if you need further help.
