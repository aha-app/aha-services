This two-way integration allows you to push your features and requirements in Aha! into FogBugz and get status changes back.

## Features

* One Aha! workspace is associated with one FogBugz project.
* Individual features can be sent to FogBugz using the _Send to FogBugz_ item in the _Send_ dropdown on the features page.
* All features in a release (that have not already been implemented or sent to FogBugz previously) can be sent to FogBugz using the _Send_ dropdown next to the Integrations field for for release pages.
* When a feature is copied to FogBugz one issue will be created for the feature.
* Only the description of a feature is sent and its requirements are created as sub-cases. No tasks or comments are included. 
* Attachments of a feature and requirements are also sent.
* Tags on a feature in Aha! will becomes tags in FogBugz.
* After a feature is first sent to FogBugz, changes to the name, description and tags, can also be sent to FogBugz using the _Update FogBugz_ item in the _Send_ dropdown next to the Integrations field. If an attachment is deleted in Aha! the corresponding attachment in FogBugz is not deleted.


## Configuration

You need to be an owner in Aha! to set up this integration.

Please carefully follow these instructions to ensure that the integration is properly configured.

Create the integration in Aha!

1. Enter your FogBugz URL and API token. Click the _Test connection_ button
2. After a short delay, you will be able to choose the Projects the cases will be created in.
3. Enable the integration.
4. Test the integration by going to one of your features in Aha! and using the FogBugz using the _Send_ dropdown next to the Integrations field for the features pages. You should then look at your FogBugz project and see that the feature were properly copied to a case.

Enable URL triggers in FogBugz to get status changes back:

1. Copy the Hook URL from the integrations page in Aha
2. In FogBugz open the settings and select URL triggers
3. Create a new trigger select All case events
4. Paste in the Hook URL and append '?case_number={CaseNumber}'
5. Select POST
6. Name you trigger Aha and create it.

## API token

You need an API token to use the FogBugz integration. You find out how to get an api token [here](http://help.fogcreek.com/8447/how-to-get-a-fogbugz-xml-api-token).


## Troubleshooting

To help you troubleshoot an error, we provide the detailed integration logs below. Contact us at support@aha.io if you need further help.
