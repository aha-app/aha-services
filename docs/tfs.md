This integration allows you to push features and requirements in Aha! into the Microsoft Team Foundation server.

##Features


* One Aha! product is associated with one Microsoft Team Fondation project.
* An feature can be sent to the Mirosoft Team Fondation server using the _Send to Tfs_ item in the _Action_ menu on the features page.
* Requirements are sent to TFS together with the feature.
* Only the name, description and attachments of features and requirements are sent.
* The type of workitem a feature or a requirement is mapped to is configurable.
* If you set up a subscription in TFS the integration can receive updates about name changes, description changes or status changes.
* The mapping of TFS states to Aha! workflow statuses is configurable.

##Configuration

You need to be Product Owner in Aha! to set up this integration.

To configure this integration, first configure your Visual Studio Online account.

1. Go to _My profile_ and then choose the _Credentials_ tab.
2. Set up the _Alternate Authentication Credentials_.

Next create the integration in Aha!

1. Enter the account name of your Visual Studio Online account. It is equal to the subdomain of your Visual Studio Online account.
2. Enter the credentials you created in Visual Studio Online.
3. Click the _Test connection_ button.
4. On success, you should be able to choose a project from Visual Studio Online. You also must select an area of this project where features and requirements should be created.
5. Select the workitemtype to which features should be mapped. Then select for each TFS state to which Aha! workflow status it should be mapped.
6. Repeat step 5 for requirements.
7. Enable the integration and test it by going to one of your features in Aha! and using the _Send to Tfs_ item in the _Action_ menu.
8. The feature should now appear in your Visual Studio Online project together with its requirements.

If you want to be able to receive updates from TFS you must setup a subscription.

1. Copy the Webhook URL from the configuration page.
2. In your Visual Studio Online account, go to the project you want to integrate with.
3. Click the small cog in the top right corner to go to the settings.
4. Click on the _Service Hooks_ tab.
5. Add a new service hook by clicking the green plus.
6. Choose the _Web Hooks_ service and click _Next_.
7. Choose the _Work item updated_ trigger from the dropdown menu. You can leave the filters unchanged and click _Next_.
8. In the _Action_ settings, paste the Webhook URL from Aha! into the _URL_ field.
9. Press _Finish_ to create the subscription.

## Troubleshooting

To help you troubleshoot an error, we provide the detailed integration logs below. Contact us at support@aha.io if you need further help.
