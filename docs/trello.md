This two-way integration allows you to push your features and requirements in Aha! into Trello and get list/status changes back.

## Features

* One Aha! workspace is associated with one Trello board.
* Individual features can be sent to Trello using the _Send to Trello_ item in the _Send_ dropdown next to the Integrations field on the features page.
* All features in a release (that have not already been implemented or sent to Trello previously) can be sent to Trello using the _Send to Trello_ item in the _Send_ dropdown next to the Integrations field on the release page.
* When a feature is copied to Trello one card will be created for the feature. If the feature has requirements then each requirement will become a checklist item on the feature card. The requirement description will be concatenated with the name - so Trello does not work well with long requirement descriptions.
* Only the description of a feature or requirement is sent. No tasks or comments are included. 
* Attachments of a feature or requirement are also sent.
* The due date of the card will be set to the release date of the release the feature belongs to.
* After a feature is first sent to Trello, changes to the name, description and requirements, can also be sent to Trello using the _Update Trello_ item in the _Send_ dropdown next to the Integrations field on the features page or by sending all features in a release to Trello again. New requirements will also be created in Trello, however checklist items that were created for an existing requirement are not deleted from Trello if the requirement is deleted from Aha!. If an attachment is deleted in Aha! the corresponding attachment in Trello is not deleted.

## Configuration

You need to be an owner in Aha! to set up this integration.

Please carefully follow these instructions to ensure that the integration is properly configured.

1. Click on the _Authenticate_ button. You will be taken to a screen to log into your Trello account and approve the Aha! integration.
2. Click the _Test connection_ button.
3. After a short delay, you will be able to choose the Board the cards will be created in.
4. Each list in the Trello board can map to a different feature status in Aha!
5. Choose the list that new features should be created in, and whether they should be added to the top or bottom of the list.
6. Enable the integration.
7. Test the integration by going to one of your features in Aha! and using the _Send to Trello_ item in the _Send_ dropdown next to the Integrations field on the features page. You should then look at your board in Trello and see that the feature (and any requirements) were properly copied.


## Troubleshooting

To help you troubleshoot an error, we provide the detailed integration logs below. Contact us at support@aha.io if you need further help.
