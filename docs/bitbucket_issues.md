This one-way integration allows you to push your features and requirements in Aha! into Bitbucket as issues. 

## Features

* One Aha! product is associated with one Bitbucket respository.
* Individual features can be sent to Bitbucket using the _Send to Bitbucket Issues_ item in the _Actions_ menu on the features page.
* All features in a release (that have not already been implemented or sent to Bitbucket previously) can be sent to Bitbucket using the _Send to Bitbucket Issues_ item in the _Actions_ menu on the release page.
* When a feature is copied to Bitbucket one issue will be created for the feature. If 
  the feature has requirements then each requirement will also be sent as an issue.
* Only the description of a feature or requirement is sent. No tasks or comments are included. 
* Attachments of a feature or requirement are also sent.
* Tags on a feature in Aha! will becomes labels in Bitbucket.
* Aha! releases will be created as milestones in Bitbucket.
* When a feature is sent to Bitbucket, its status in Aha! is automatically changed to Ready to develop.
* After a feature is first sent to Bitbucket, changes to the name, description and requirements, can also be sent to Bitbucket using the _Update Bitbucket Issues_ item in the _Actions_ menu on the features page or by sending all features in a release to Bitbucket again. New requirements will also be created in Bitbucket, however issues that were created for an existing requirement are not deleted from Bitbucket if the requirement is deleted from Aha!. If an attachment is deleted in Aha! the corresponding attachment in Bitbucket is not deleted. 


## Configuration

You need to be a Product Owner in Aha! to set up this integration.

Please carefully follow these instructions to ensure that the integration is properly configured.

Create the integration in Aha!

1. Enter your Bitbucket username and password. Click the _Test connection_ button
2. After a short delay, you will be able to choose the repository the issues will be created in.
3. Enable the integration.
4. Test the integration by going to one of your features in Aha! and using the _Send to Bitbucket Issues_ item in the _Actions_ menu on the features page. You should then look at your repository in Bitbucket and see that the feature (and any requirements) were properly copied to issues. 


## Troubleshooting

To help you troubleshoot an error, we provide the detailed integration logs below. Contact us at support@aha.io if you need further help.
