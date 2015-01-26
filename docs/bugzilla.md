This integration allows you to push features and requirements from Aha! to a Bugzilla installation.

This integration uses the REST API of Bugzilla version 5.0.

## Features

* One Aha! product is associated with one product and component in Bugzilla.
* A feature can be sent to Bugzilla using the _Send to Bugzilla_ item in the _Action_ menu on the features page.
* Requirements are sent to Bugzilla together with the feature.
* Only the name, description and attachments of features and requirements are sent.
* Bugs created from a requirement will block the bug created from the feature.

## Configuration

You need to be Product Owner in Aha! to set up this integration.

To configure this integration you need an API key from Bugzilla.

1. Go to _Preferences_ and then choose the _API Keys_ tab.
2. Create a new API key or use an existing one. Be aware that the integration will only have the permissions of the user that created the API key.

Next create the integration in Aha!

1. Enter the URL of your Bugzilla installation.
2. Enter the API key you created in Bugzilla.
3. Click the _Test connection_ button.
4. On success, you should be able to choose a product and a component from Bugzilla.
5. Enable the integration and test it by going to one of your features in Aha! and using the _Send to Bugzilla_ item in the _Action_ menu.
6. The feature should appear as a bug in Bugzilla and the requirements should appear as bugs that block the first bug.

## Troubleshooting

To help you troubleshoot an error, we provide the detailed integration logs below. Contact us at support@aha.io if you need further help.
