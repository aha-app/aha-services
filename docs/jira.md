This bi-directional integration allows you to push your completed features and requirements in Aha! into Jira. It also automatically updates your features and requirements in Aha! if text or status changes are made in Jira. This integration works with both the hosted and on prem versions of Jira. Note that if you are running the downloaded, on prem version of Jira you will need to create a firewall exception so Aha! can make calls to the Jira API. The exception should forward requests to the internal Jira server. 

*Note* there are two separate integrations with Jira. Both have the same basic functionality, they differ in how they are authenticated and the installation procedure. You only need to enable one.

1. Jira - this integration uses the username and password of a Jira user to authenticate with Jira. Can be used with downloaded or on-demand versions of Jira.
2. Jira via Connect - this integration uses an Add-on that is installed into your Jira instance by an administrator. Can only be used with Jira on-demand.

## Features

The integration supports features and requirements being sent from Aha! to Jira and updates in Jira being sent back and reflected in Aha!

From Aha! to Jira

* One Aha! product is associated with one Jira project.
* Individual features can be sent to Jira using the _Send to Jira_ item in the _Actions_ menu on the features page.
* All features in a release (that have not already been implemented or sent to Jira previously) can be sent to Jira using the _Send to Jira_ item in the _Actions_ menu on the release page.
* When a feature is copied to Jira one issue will be created for the feature. If 
  the feature has requirements then each requirement will also be sent as a 
  linked issue of the feature issue.
* Only the description of a feature or requirement is sent. No tasks or comments are included. 
* Attachments of a feature or requirement are also sent.
* When a feature is sent to Jira, its status in Aha! is automatically changed to Ready to develop.
* After a feature is first to Jira, changes to the name, description, requirements or attachments, can also be sent to Jira using the _Update Jira_ item in the _Actions_ menu on the features page or by sending all features in a release to Jira again. New requirements will also be created in Jira, however issues that were created for an existing requirement are not deleted from Jira if the requirement is deleted from Aha!. If an attachment is deleted in Aha! the corresponding attachment in Jira is not deleted. 

From Jira to Aha!

* Any comments that are added to the Jira issue will also be automatically added to the Aha! item that the issue was created from.
* Changes to the status of a Jira issue will be reflected in the Aha! item the issue was created from.
* Other text changes to the Jira issue will also cause a comment to be added to the Aha! item reflecting the change.

The integration will also create a version in Jira when you send a release from Aha!

* Send a release to Jira by using the _Send to Jira_ item in the _Actions_ menu on the release page.
* When a release is first sent to Jira a corresponding version record will be created in Jira. The name and date on the version will be based on the release.
* Each time the release is sent to Jira again the name and release date will be updated to match the release in Aha!. Changes to the version in Jira will not be reflected back in Aha!.
* Each feature in the release which has a corresponding issue in Jira will have its version field set to the version that was created. When features are moved between releases in Aha! the version field in Jira will be updated to match.
* If a version already exists in Jira with the same name as the Aha! release, then a new version will not be created and there will be no link between the Aha! release and the Jira version.

## Configuration

You need to be a Product Owner in Aha! and an Administrator in Jira to set up this integration.

Please carefully follow these instructions to ensure that the integration is properly configured.

1.	Configure the Server URL, Username and Password below. Click the _Test connection_ button
2.	After a short delay, you will be able to choose the Project the issues will be created in.
3. 	Map how you want new features to show up in Jira and how the Jira status fields should map to Aha! 
3.	Copy the Hook URL below. In the Jira administration section on the _System_ tab, choose _Webhooks_.
4.	Create a new _Webhook_ in Jira and paste in the Hook URL that you copied. This will allow enable the features listed above in the From Jira to Aha! section.
5.	Enable the integration.
6. 	Test the integration by going to one of your features in Aha! and using the _Send to Jira_ item in the _Actions_ menu on the features page. You should then look at your project in Jira and see that the feature (and any requirements) were properly copied. 


## Troubleshooting

There are a number of common problems to watch out for and steps to take if you have a problem. To help you troubleshoot an error, we provide the detailed integration logs below. 

1. Look in the logs below.
2. Creating issues may fail if you have required fields in your Jira project that are in addition to the default fields. You must make these fields optional in Jira.
3. Your Jira system must have an issue link named Relates and issue linking must be turned on. This is included and is on by default.
4. If your changes in Jira are not being reflected in Aha! check the Installation instructions for _Webhooks_. 
5. Contact us at support@aha.io




