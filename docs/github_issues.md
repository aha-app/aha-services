This two-way integration allows you to push your features and requirements in Aha! into GitHub as issues and get status updates back.

## Features

* One Aha! product can be associated with one or many GitHub repositories. If the association is one to many, you need to set up different integrations for each product - repository mapping.
* Individual features can be sent to GitHub using the _Send to GitHub_ issues item in the _Send_ dropdown on the features page.
* All features in a release (that have not already been implemented or sent to GitHub previously) can be sent to GitHub using the _Send_ dropdown next to the Integrations field on the release page.
* When a feature is copied to GitHub one issue will be created for the feature.
* There are two ways to map requirements to issues. Each requirement can be mapped to a stand-alone issue, or the requirements can be converted to a checklist within the main issue. If checklists are used, note that there are some significant caveats:
  * When checklist items are ticked, the status of the corresponding requirement in Aha! will not be updated.
  * Each time the feature is updated in GitHub using the _Update GitHub_ menu item in the _Send_ dropdown, the entire issue description will be overwritten, reseting the status of any checklist items that are already complete.
* Only the description of a feature or requirement is sent. No tasks or comments are included.
* Attachments of a feature or requirement are also sent.
* Tags on a feature in Aha! will becomes labels in GitHub.
* Aha! releases will be created as milestones in GitHub.
* After a feature is first sent to GitHub, changes to the name, description and requirements, can also be sent to GitHub using the _Update GitHub_ item in the _Actions_ menu on the features page or by sending all features in a release to GitHub again. New requirements will also be created in GitHub, however issues that were created for an existing requirement are not deleted from GitHub if the requirement is deleted from Aha!. If an attachment is deleted in Aha! the corresponding attachment in GitHub is not deleted.
* When "Add status labels" is enabled and the feature is updated using _Send_ to GitHub Issues, the state of the feature will be added as a label in GitHub with the prefix "Aha!:" i.e. "Aha!:In development".
* With "Add status labels" enabled, the state of an Aha! feature corresponding to a GitHub issue can be changed to the desired Aha! state by adding a GitHub label with the "Aha!:" prefix and removing the label representing the feature's previous state. For example, to change the Aha! status from "In development" to "Ready to ship", remove the label "Aha!:In development" and add the label "Aha!:Ready to ship". Note: only one label with the prefix "Aha!:" will be allowed on a GitHub issue

## Configuration

You need to be a Product Owner in Aha! to set up this integration.

Please carefully follow these instructions to ensure that the integration is properly configured.

Create the integration in Aha!

1. Enter your GitHub username and password. Consider using a [GitHub Personal Token](https://help.github.com/articles/creating-an-access-token-for-command-line-use) rather than a password here. A token is essential if you use two-factor authentication with your GitHub account. Click the _Test connection_ button
2. After a short delay, you will be able to choose the repository the issues will be created in.
3. Enable the integration.
4. Test the integration by going to one of your features in Aha! and using the _Send to GitHub Issues_ item in the _Send_ dropdown on the features page. You should then look at your repository in GitHub and see that the feature (and any requirements) were properly copied to issues.

To receive updates when an issue is changed on GitHub you have to setup a webhook for the GitHub repository.

1. In Aha!, copy the Webhook URL from the GitHub issues integration settings.
2. On GitHub, go to the settings page of the GitHub repository and click on the _Webhooks & Services_ tab.
3. Add a new webhook.
4. Paste the Webhook URL into the _Payload URL_ field. Choose _application/json_ as content type and leave the secret field blank.
5. Select _Let me select individual events._ and then check only _Issues_.
6. Finally, click _Add webhook_.

In the GitHub issues integration settings, you can choose to which Aha! status the "Open" or "Closed" state of an issue should map.

## Troubleshooting

To help you troubleshoot an error, we provide the detailed integration logs below. Contact us at support@aha.io if you need further help.
