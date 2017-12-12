This bi-directional integration allows you to push your completed features and requirements in Aha! into Jira. It also automatically updates your features and requirements in Aha! if status changes are made in Jira. 

Note there are two separate integrations with Jira. Both have the same basic functionality, they differ in how they are authenticated and the installation procedure. You only need to enable one. At this time, we recommend that you use the first Jira approach unless you already have set up the second.

1. Jira (RECOMMENDED) - this integration uses the username and password of a Jira user to authenticate with Jira. It can be used with downloaded or cloud versions of Jira.
2. Jira via Connect - this integration uses an Add-on that is installed into your Jira instance by an administrator. It can only be used with Jira cloud and is restricted to integration with a single Jira server.  

## Aha! to Jira workflow

Aha! is for the "why" and "what" and Jira is for the "how." Do your product strategy, roadmapping, and feature definition in Aha! and push the items to Jira for engineering to build. Aha! comes first and Jira second. We then keep the features up-to-date in Aha! as engineering does their work. Please read the following documents in order to make sure you configure the integration to best work for you. 

* Learn more about the [integration workflow](http://support.aha.io/entries/25419983)

## Integration capabilities

The integration supports features and requirements being sent from Aha! to Jira and updates in Jira being sent back and reflected in Aha!

* Learn more about the [overall integration capabilities](http://support.aha.io/entries/40846667)
* If you use Jira Agile, [read this for feature mapping](http://support.aha.io/entries/40551483)
* If you use Jira, [read this for feature mapping](http://support.aha.io/entries/40843667)

## Configuration

You need to be a Product Owner in Aha! and an Administrator in Jira to set up this integration.

This integration only works with the cloud version of Jira. 

Please carefully follow these instructions to ensure that the integration is properly configured.

1. Log into your Jira Cloud instance. Under _Administration_ -> _Add-ons_ use the _Find new add-ons_ screen to find the _Aha! Product Roadmaps_ add-on and install it.
2. Click on the _Configure_ button to configure the _Aha! Product Roadmaps_ add-on.
3. Enter the sub-domain of your Aha! instance and save.
4. Log into Aha! and find the _Account settings_ -> _Integrations_ -> _Jira via Connect_ page for the product you want to integrate with Jira.
5. Click the _Test connection_ button to verify that the add-on was installed correctly and load the configuration from Jira.
6. After a short delay, you will be able to choose the Project the issues will be created in.
7. Map how you want new features to show up in Jira and how the Jira status fields should map to Aha! 
8. Enable the integration.
9. Test the integration by going to one of your features in Aha! and using the _Send to Jira_ item in the _Actions_ menu on the features page. You should then look at your project in Jira and see that the feature (and any requirements) were properly copied. 

If multiple Aha! products are being integrated with Jira, then the steps 1 to 3 only need to be completed once. Step 4 onwards must be repeated for each product.

If you want to have issues created in Jira automatically imported into Aha! then it is necessary to also create a webhook in Jira:

1.	Copy the Webhook URL below. In the Jira administration section on the _System_ tab, choose _Webhooks_.
2.	Create a new _Webhook_ in Jira and paste in the Webhook URL that you copied. Check the boxes for all _Worklog_ and _Issue_ events. This will enable changes in Jira to be reflected in Aha!. Only one webhook should be created per Aha! account.


## Troubleshooting

There are a number of common problems to watch out for and steps to take if you have a problem. To help you troubleshoot an error, we provide the detailed integration logs below. 

1. Look in the logs below.
2. Creating issues may fail if you have required fields in your Jira project that are in addition to the default fields. You must make these fields optional in Jira or map custom fields in Aha! to them.
3. Your Jira system must have an issue link named Relates and issue linking must be turned on. This is included and is on by default.
4. If your changes in Jira are not being reflected in Aha! check the Installation instructions for _Webhooks_. 
5. Check the [support documentation](http://support.aha.io/forums/22978468).
6. Contact us at support@aha.io







