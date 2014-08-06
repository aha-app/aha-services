This two-way integration allows you to push your features and requirements in Aha! into Fogbugz and get status changes back.

## Features

* One Aha! product is associated with one Fogbugz project.
* Individual features can be sent to Fogbugz using the _Send to Fogbugz_ item in the _Actions_ menu on the features page.
* All features in a release (that have not already been implemented or sent to Fogbugz previously) can be sent to Fogbugz using the _Send to Fogbugz_ item in the _Actions_ menu on the release page.
* When a feature is copied to Fogbugz one issue will be created for the feature.
* Only the description of a feature is sent and its requirements are created as sub-cases. No tasks or comments are included. 
* Attachments of a feature and requirements are also sent.
* Tags on a feature in Aha! will becomes tags in Fogbugz.
* After a feature is first sent to Fogbugz, changes to the name, description and tags, can also be sent to Fogbugz using the _Update Fogbugz item in the _Actions_ menu on the features page. If an attachment is deleted in Aha! the corresponding attachment in Fogbugz is not deleted. 


## Configuration

You need to be a Product Owner in Aha! to set up this integration.

Please carefully follow these instructions to ensure that the integration is properly configured.

Create the integration in Aha!

1. Click on the _Create integration_ button below.
2. Enter your Fogbugz URL and API key. Click the _Test connection_ button
3. After a short delay, you will be able to choose the Projects the cases will be created in.
4. Enable the integration.
5. Test the integration by going to one of your features in Aha! and using the _Send to Fogbugz_ item in the _Actions_ menu on the features page. You should then look at your Fogbugz project and see that the feature were properly copied to a case. 

Enable URL triggers in Fogbugz to get status changes back!

1. Copy the Hook URL from the integrations page in Aha
2. In Fogbugz open the settings and select URL triggers
3. Create a new trigger select All case events
4. Paste in the Hook URL and append '?case_number=\#{CaseNumber}'
5. Select POST
6. Name you trigger Aha and create it.

## API keys

You need an Api key to use the fogbugz integration. You find out how to get an api key here.
http://help.fogcreek.com/8447/how-to-get-a-fogbugz-xml-api-token


## Troubleshooting

To help you troubleshoot an error, we provide the detailed integration logs below. Contact us at support@aha.io if you need further help.
