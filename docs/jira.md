This integration will allow Aha! features and requirements to be turned
into issues in a Jira instance (either on-demand or downloaded).

Features
--------

* Individual features, or all features in a release, can be sent to Jira
  using the _Send to Jira_ item in the _Actions_ menu on a feature or release.
* One Aha! product is associated with one Jira project.
* When a feature is copied to Jira one issue will be created for the feature. If
  the feature has requirements then each requirement will also be copied as a
  sub-issue of the feature issue.
* Only the description of a feature or requirement is copied - **not** any of the
  comments for the item.
* Attachments of a feature or requirement **are** copied.
* Any changes that are made to the Aha! item once it is copied to Jira will
  not be reflected in the Jira issue.
* Any comments that are added to the Jira issue will also be added to the 
  Aha! item that the issue was created from.
* Changes to the status of a Jira issue will be reflected in the Aha! item
  the issue was created from.
* Other changes in the Jira issue will also cause a comment to be added to
  the Aha! item describing the change.
* Comments in Aha! that are created based on activity in Jira will be created
  using the Aha! account of the user that made the change in Jira, if the user
  has the same email address in both systems. Otherwise the items in Aha! will
  be created using the name of the user who configured this integration.

Installation
------------

1. Configure the _Server URL_, _Username_ and _Password_ below.
2. After a short delay you will be able to choose the _Project_ the issues
  will be created in, and then the other settings.
3. Copy the _Hook URL_. In the Jira _Administration_ section on the _System_
  tab, choose _Webhooks_.
4. Create a new web hook and paste in the _Hook URL_. This will allow Aha!
  to be notified when changes are made to Jira issues.
5. Enable the integration.

Firewall considerations
-----------------------

If you are running the downloaded version of Jira you will need to create a
firewall exception so that Aha! can make calls to the Jira API. The exception
should forward requests to the internal Jira server.
