This bi-directional integration allows you to push your completed features and requirements in Aha! into JIRA. It also automatically updates your features and requirements in Aha! if status changes are made in JIRA. This integration works with both the on-demand and on premise versions of JIRA. Note that if you are running the downloaded, on premise version of JIRA you will need to create a firewall exception so Aha! can make calls to the JIRA API. The exception should forward requests to the internal JIRA server. 

*Note* there are two separate integrations with JIRA. Both have the same basic functionality, they differ in how they are authenticated and the installation procedure. You only need to enable one.

1. JIRA - this integration uses the username and password of a JIRA user to authenticate with JIRA. It can be used with downloaded or on-demand versions of JIRA.
2. JIRA via Connect - this integration uses an Add-on that is installed into your JIRA instance by an administrator. It can only be used with JIRA on-demand.

This is the page to configure JIRA with username and password.

## Features

The integration supports features and requirements being sent from Aha! to JIRA and updates in JIRA being sent back and reflected in Aha!

From Aha! to JIRA

* One Aha! product is associated with one JIRA project.
* Individual features can be sent to JIRA using the _Send to JIRA_ item in the _Actions_ menu on the features page.
* All features in a release (that have not already been implemented or sent to JIRA previously) can be sent to JIRA using the _Send to JIRA_ item in the _Actions_ menu on the release page.
* When a feature is copied to JIRA one issue will be created for the feature. If 
  the feature has requirements then each requirement will also be sent as a 
  linked issue of the feature issue (or a story under an epic if you choose the Epic and Story issue types).
* Only the description of a feature or requirement is sent. No tasks or comments are included. 
* Attachments of a feature or requirement are also sent.
* When a feature is sent to JIRA, its status in Aha! is automatically changed to Ready to develop.
* After a feature is first sent to JIRA, changes to the name, description, requirements or attachments, can also be sent to JIRA using the _Update JIRA_ item in the _Actions_ menu on the features page or by sending all features in a release to JIRA again. New requirements will also be created in JIRA, however issues that were created for an existing requirement are not deleted from JIRA if the requirement is deleted from Aha!. If an attachment is deleted in Aha! the corresponding attachment in JIRA is not deleted. 

From JIRA to Aha!

* Any comments that are added to the JIRA issue will also be automatically added to the Aha! item that the issue was created from.
* Changes to the status, name or description of a JIRA issue will be reflected in the Aha! item the issue was created from. Any other changes will cause a comment to be added to the Aha! item describing the change.

The integration will also create a version in JIRA when you send a release from Aha!

* Send a release to JIRA by using the _Send to JIRA_ item in the _Actions_ menu on the release page.
* When a release is first sent to JIRA a corresponding version record will be created in JIRA. The name and date on the version will be based on the release.
* Each time the release is sent to JIRA again the name and release date will be updated to match the release in Aha!. Changes to the version in JIRA will not be reflected back in Aha!.
* Each feature in the release which has a corresponding issue in JIRA will have its version field set to the version that was created. When features are moved between releases in Aha! the version field in JIRA will be updated to match.
* If a version already exists in JIRA with the same name as the Aha! release, then a new version will not be created and there will be no link between the Aha! release and the JIRA version.

## Configuration

You need to be a Product Owner in Aha! and an Administrator in JIRA to set up this integration.

Please carefully follow these instructions to ensure that the integration is properly configured.

1. Click on the _Create integration_ button below.
2.	Configure the Server URL, Username and Password below. Click the _Test connection_ button
3.	After a short delay, you will be able to choose the Project the issues will be created in.
4. 	Map how you want new features to show up in JIRA and how the JIRA status fields should map to Aha! 
5.	Copy the Hook URL below. In the JIRA administration section on the _System_ tab, choose _Webhooks_.
6.	Create a new _Webhook_ in JIRA and paste in the Hook URL that you copied. Enable _All issue events_. This will allow enable the features listed above in the From JIRA to Aha! section. Only one webhook should be created per Aha! account.
7.	Enable the integration.
8. 	Test the integration by going to one of your features in Aha! and using the _Send to JIRA_ item in the _Actions_ menu on the features page. You should then look at your project in JIRA and see that the feature (and any requirements) were properly copied. 


## Troubleshooting

There are a number of common problems to watch out for and steps to take if you have a problem. To help you troubleshoot an error, we provide the detailed integration logs below. 

1. Look in the logs below.
2. Creating issues may fail if you have required fields in your JIRA project that are in addition to the default fields. You must make these fields optional in JIRA.
3. Your JIRA system must have an issue link named Relates and issue linking must be turned on. This is included and is on by default.
4. If your changes in JIRA are not being reflected in Aha! check the Installation instructions for _Webhooks_. 
5. Contact us at support@aha.io




