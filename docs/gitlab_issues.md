This two-way integration allows you to push your features and requirements in Aha! into GitLab as issues and get status updates back.

## Features

* One Aha! product can be associated with one or many GitLab projects. If the association is one to many, you need to set up different integrations for each product - project mapping.
* Individual features can be sent to GitLab using the _Send to GitLab Issues_ item in the _Actions_ menu on the features page.
* All features in a release (that have not already been implemented or sent to GitLab previously) can be sent to GitLab using the _Send to GitLab Issues_ item in the _Actions_ menu on the release page.
* When a feature is copied to GitLab one issue will be created for the feature.
* There are two ways to map requirements to issues. Each requirement can be mapped to a stand-alone issue, or the requirements can be converted to a checklist within the main issue. If checklists are used, note that there are some significant caveats:
  * When checklist items are ticked, the status of the corresponding requirement in Aha! will not be updated.
  * Each time the feature is updated in GitLab using the _Update GitLab_ menu item, the entire issue description will be overwritten, reseting the status of any checklist items that are already complete.
* Only the description of a feature or requirement is sent. No tasks or comments are included.
* Attachments of a feature or requirement are also sent.
* Tags on a feature in Aha! will becomes labels in GitLab.
* Aha! releases will be created as milestones in GitLab.
  * The milestone due date will be the end date of a user defined release phase. Falls back to the release date if this is not set or if the named release phase does not exist.
* After a feature is first sent to GitLab, changes to the name, description and requirements, can also be sent to GitLab using the _Update GitLab_ item in the _Actions_ menu on the features page or by sending all features in a release to GitLab again. New requirements will also be created in GitLab, however issues that were created for an existing requirement are not deleted from GitLab if the requirement is deleted from Aha!. If an attachment is deleted in Aha! the corresponding attachment in GitLab is not deleted.
* When "Add status labels" is enabled and the feature is updated using _Send to GitLab Issues_, the state of the feature will be added as a label in GitLab with the prefix "Aha!:" i.e. "Aha!:In development".
* With "Add status labels" enabled, the state of an Aha! feature corresponding to a GitLab issue can be changed to the desired Aha! state by adding a GitLab label with the "Aha!:" prefix and removing the label representing the feature's previous state. For example, to change the Aha! status from "In development" to "Ready to ship", remove the label "Aha!:In development" and add the label "Aha!:Ready to ship". Note: only one label with the prefix "Aha!:" will be allowed on a GitLab issue

## Configuration

You need to be a Product Owner in Aha! to set up this integration.

Please carefully follow these instructions to ensure that the integration is properly configured.

Create the integration in Aha!

1. Enter your [GitLab Personal Token](https://gitlab.com/help/profile/two_factor_authentication.md#personal-access-tokens).
Click the _Test connection_ button
2. After a short delay, you will be able to choose the project the issues will be created in.
3. Enable the integration.
4. Test the integration by going to one of your features in Aha! and using the _Send to GitLab Issues_ item in the _Actions_ menu on the features page. You should then look at your repository in GitLab and see that the feature (and any requirements) were properly copied to issues.

To receive updates when an issue is changed on GitLab you have to setup a webhook for the GitLab repository.

1. In Aha!, copy the Webhook URL from the GitLab issues integration settings.
2. On GitLab, go to the settings dropdown and select _Webhooks_ .
3. Paste the Webhook URL into the _URL_ field and leave the secret field blank. Uncheck the "Push events" box, and check the "Issues events" box for the trigger.
4. Finally, click _Add webhook_.

In the GitLab issues integration settings, you can choose to which Aha! status the "Open" or "Closed" state of an issue should map.

## Troubleshooting

To help you troubleshoot an error, we provide the detailed integration logs below. Contact us at support@aha.io if you need further help.
