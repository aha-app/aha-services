This two-way integration allows you to push your features and requirements in Aha! into Pivotal Tracker and get status changes back.

## Features

* One Aha! product is associated with one Pivotal Tracker project.
* Individual features can be sent to Pivotal Tracker using the _Send to Pivotal Tracker_ item in the _Actions_ menu on the features page.
* All features in a release (that have not already been implemented or sent to Pivotal Tracker previously) can be sent to Pivotal Tracker using the _Send to Pivotal Tracker_ item in the _Actions_ menu on the release page.
* How the features and requirements will be mapped to epics, stories and tasks
in Pivotal Tracker will depend on the _Mapping_ field.
* Only the description of a feature or requirement is sent. No tasks or comments are included. 
* Attachments of a feature or requirement are also sent, unless requirements
are mapped to tasks in which case no requirement attachments will be sent.
* After a feature is first sent to Pivotal Tracker, changes to the name, description and requirements, can also be sent to Pivotal Tracker using the _Update Pivotal Tracker_ item in the _Actions_ menu on the features page or by sending all features in a release to Pivotal Tracker again. New requirements will also be created in Pivotal Tracker, however stories that were created for an existing requirement are not deleted from Pivotal Tracker if the requirement is deleted from Aha!. If an attachment is deleted in Aha! the corresponding attachment in Pivotal Tracker is not deleted. 

## Configuration

You need to be a Product Owner in Aha! to set up this integration.

Please carefully follow these instructions to ensure that the integration is properly configured.

First configure Pivotal Tracker:

1. Go to the _Settings_ page for the project, and then choose the _Integrations_ tab.
2. Under _External Tool Integrations_ at the bottom of the page, create a new _Other_ integration.
3. Name the integration "Aha", and set the _Base URL_ to "https://&lt;yourdomain&gt;.aha.io/features" (where &lt;yourdomain&gt; is the sub-domain for your account).
4. Mark the integration as _Active_, leave the other fields blank and save the integration.
5. On the _Profile_ page, copy the _API token_.

Next create the integration in Aha!

1. Click on the _Create integration_ button below.
2. Enter the API token you copied from Pivotal Tracker. Click the _Test connection_ button
3. After a short delay, you will be able to choose the Project the stories will be created in.
4. Choose the integration in Pivotal Tracker that you created in step 2 above.
5.	Create a new _Activity Web Hook_ for v5 in Pivotal Tracker and paste in the Hook URL.
6. Enable the integration.
7. Test the integration by going to one of your features in Aha! and using the _Send to Pivotal Tracker_ item in the _Actions_ menu on the features page. You should then look at your project in Pivotal Tracker and see that the feature (and any requirements) were properly copied. 


## Troubleshooting

To help you troubleshoot an error, we provide the detailed integration logs below. Contact us at support@aha.io if you need further help.
