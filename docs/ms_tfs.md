This integration allows you to push features and requirements in Aha! into the Microsoft Team Foundation server.

##Features

* One Aha! product is associated with one Microsoft Team Fondation project.
* An feature can be sent to the Microsoft Team Fondation server using the _Send to Ms tfs_ item in the _Action_ menu on the features page.
* A feature is mapped to a feature. The _Requirements mapping_ fields determins the mapping from requirements to either user stories, requirements or product backlog items. You can choose the appropriate mapping for your project template.
* Only the feature name and description is sent as well as the requirements.

##Configuration

You need to be Product Owner in Aha! to set up this integration.

To configure this integration, first configure your Visual Studio Online account.

1. Go to _My profile_ and then choose the _Credentials_ tab.
2. Set up the _Alternate Authentication Credentials_.

Next create the integration in Aha!

1. Enter the account name of your Visual Studio Online account. It is equal to the subdomain of your Visual Studio Online account.
2. Enter the credentials you created in Visual Studio Online.
3. Click the _Test connection_ button.
4. On success, you should be able to choose a project from Visual Studio Online. You also have to select a mapping for requirements.
5. Enable the integration and test it by going to one of your features in Aha! and using the _Send to Ms Tfs_ item in the _Action_ menu.
6. The feature should now appear in your Visual Studio Online project together with its requirements.

## Troubleshooting

To help you troubleshoot an error, we provide the detailed integration logs below. Contact us at support@aha.io if you need further help.
