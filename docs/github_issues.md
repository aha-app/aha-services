This one-way integration allows you to push your features and requirements in Aha! into Github as issues. 

## Features

* One Aha! product is associated with one Github respository.
* Individual features can be sent to Github using the _Send to Github Issues_ item in the _Actions_ menu on the features page.
* All features in a release (that have not already been implemented or sent to Github previously) can be sent to Github using the _Send to Github Issues_ item in the _Actions_ menu on the release page.
* When a feature is copied to Github one issue will be created for the feature. If 
  the feature has requirements then each requirement will also be sent as an issue.
* Only the description of a feature or requirement is sent. No tasks or comments are included. 
* Attachments of a feature or requirement are also sent.
* Tags on a feature in Aha! will becomes labels in Github.
* Aha! releases will be created as milestones in Github.
* When a feature is sent to Github, its status in Aha! is automatically changed to Ready to develop.
* After a feature is first sent to Github, changes to the name, description and requirements, can also be sent to Github using the _Update Github_ item in the _Actions_ menu on the features page or by sending all features in a release to Github again. New requirements will also be created in Github, however issues that were created for an existing requirement are not deleted from Github if the requirement is deleted from Aha!. If an attachment is deleted in Aha! the corresponding attachment in Github is not deleted. 


## Configuration

You need to be a Product Owner in Aha! to set up this integration.

Please carefully follow these instructions to ensure that the integration is properly configured.

Create the integration in Aha!

1. Enter your Github username and password. Consider using a [Github Personal Token](https://help.github.com/articles/creating-an-access-token-for-command-line-use) rather than a password here. A token is essential if you use two-factor authentication with your Github account. Click the _Test connection_ button
2. After a short delay, you will be able to choose the repository the issues will be created in.
3. Enable the integration.
4. Test the integration by going to one of your features in Aha! and using the _Send to Github Issues_ item in the _Actions_ menu on the features page. You should then look at your repository in Github and see that the feature (and any requirements) were properly copied to issues. 

To receive updates when an issue is changed on Github you have to setup a webhook for the Github repository.

1. In Aha!, copy the Webhook URL from the Github issues integration settings.
2. On Github, go to the settings page of the Github repository and click on the _Webhooks & Services_ tab.
3. Add a new webhook.
4. Paste the Webhook URL into the _Payload URL_ field. Choose _application/json_ as content type and leave the secret field blank.
5. Select _Let me select individual events._ and then check only _Issues_.
6. Finally, click _Add webhook_.

In the Github issues integration settings, you can choose to which Aha! status the "Open" or "Closed" state of an issue should map.

## Troubleshooting

To help you troubleshoot an error, we provide the detailed integration logs below. Contact us at support@aha.io if you need further help.
