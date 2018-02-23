This one-way integration allows you to push your features and requirements in Aha! into Redmine as issues.

## Features

* One Aha! product is associated with one Redmine project.
* Individual features can be sent to Redmine using the _Send to Redmine Issues_ item in the _Send_ dropdown next to the integrations field on the features page.
* When a feature is copied to Redmine one issue will be created for the feature. If
the feature has requirements then each requirement will also be sent as an issue.
* Only the description of a feature or requirement is sent. No tasks or comments are included.
* Attachments of a feature or requirement are also sent.
* Aha! releases will be created as versions in Redmine.
* After a feature is first sent to Redmine, changes to the name, description and requirements, can also be sent to Redmine using the _Update Redmine_ item in the _Send_ dropdown next to the integrations field on the features page or by sending all features in a release to Redmine again. New requirements will also be created in Redmine, however issues that were created for an existing requirement are not deleted from Redmine if the requirement is deleted from Aha!. If an attachment is deleted in Aha! the corresponding attachment in Redmine is not deleted.


## Configuration

You need to be a Product Owner in Aha! to set up this integration.

Please carefully follow these instructions to ensure that the integration is properly configured.

Create the integration in Aha!

1. Enter your Redmine url and the _API access key_. You can find the _API access key_ for a specific Redmine user by going to user's _My account_ page. The API access key can be revealed on the right-side menu.
2. Click the _Test connection_ button.
3. After a short delay, you will be able to choose the project the issues will be created for.
4. Enable the integration.
5. Test the integration by going to one of your features in Aha! and using the _Send to Redmine Issues_ item in the _Send_ dropdown next to the integrations field on the features page. You should then look at your Redmine project and see that the feature (and any requirements) were properly copied to issues.


## Troubleshooting

To help you troubleshoot an error, we provide the detailed integration logs below. Contact us at support@aha.io if you need further help.
