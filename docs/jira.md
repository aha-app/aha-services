This bi-directional integration allows you to push your completed features and requirements in Aha! into JIRA. It also automatically updates your features and requirements in Aha! if status changes are made in JIRA. 

Note there are two separate integrations with JIRA. Both have the same basic functionality, they differ in how they are authenticated and the installation procedure. You only need to enable one. At this time, we recommend that you use the first JIRA approach unless you already have set up the second.

1. JIRA (RECOMMENDED) - this integration uses the username and password of a JIRA user to authenticate with JIRA. It can be used with downloaded or on-demand versions of JIRA.
2. JIRA via Connect - this integration uses an Add-on that is installed into your JIRA instance by an administrator. It can only be used with JIRA on-demand.


## Aha! to JIRA workflow

Aha! is for the "why" and "what" and JIRA is for the "how." Do your product strategy, roadmapping, and feature definition in Aha! and push the items to JIRA for engineering to build. Aha! comes first and JIRA second. We then keep the features up-to-date in Aha! as engineering does their work. Please read the following documents in order to make sure you configure the integration to best work for you. 

* Learn more about the [integration workflow](http://support.aha.io/entries/25419983)

## Integration capabilities

The integration supports features and requirements being sent from Aha! to JIRA and updates in JIRA being sent back and reflected in Aha!

* Learn more about the [overall integration capabilities](http://support.aha.io/entries/40846667)
* If you use JIRA Agile, [read this for feature mapping](http://support.aha.io/entries/40551483)
* If you use JIRA, [read this for feature mapping](http://support.aha.io/entries/40843667)

## Configuration

You need to be a Product Owner in Aha! and an Administrator in JIRA to set up this integration.

This integration works with both the on-demand and on premise versions of JIRA. Note that if you are running the downloaded, on premise version of JIRA you will need to create a [firewall exception](http://support.aha.io/entries/40842777) so Aha! can make calls to the JIRA API. The exception should forward requests to the internal JIRA server.

Please carefully follow these instructions to ensure that the integration is properly configured.

1. Click on the _Create integration_ button below.
2.	Configure the Server URL, Username and Password below. Click the _Test connection_ button
3.	After a short delay, you will be able to choose the Project the issues will be created in.
4. 	Map how you want new features to show up in JIRA and how the JIRA status fields should map to Aha! 
5.	Copy the Hook URL below. In the JIRA administration section on the _System_ tab, choose _Webhooks_.
6.	Create a new _Webhook_ in JIRA and paste in the Hook URL that you copied. Enable _All issue events_. This will enable the features listed above in the From JIRA to Aha! section. Only one webhook should be created per Aha! account.
7.	Enable the integration.
8. 	Test the integration by going to one of your features in Aha! and using the _Send to JIRA_ item in the _Actions_ menu on the features page. You should then look at your project in JIRA and see that the feature (and any requirements) were properly copied. 


## Troubleshooting

There are a number of common problems to watch out for and steps to take if you have a problem. To help you troubleshoot an error, we provide the detailed integration logs below. 

1. Look in the logs below.
2. Creating issues may fail if you have required fields in your JIRA project that are in addition to the default fields. You must make these fields optional in JIRA.
3. Your JIRA system must have an issue link named Relates and issue linking must be turned on. This is included and is on by default.
4. If your changes in JIRA are not being reflected in Aha! check the Installation instructions for _Webhooks_. 
5. Check the [support documentation](http://support.aha.io/forums/22978468).
6. Contact us at support@aha.io




