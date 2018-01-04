This bi-directional integration for both on premise and cloud versions of Jira allows you to push features and requirements from Aha! into Jira.

Note there are two separate integrations with Jira, we recommend that you use the "Jira" integration over the Jira via Connect option.

1. Jira (RECOMMENDED) - This integration uses the username and password of a Jira user to authenticate with Jira. It can be used with on premise or cloud versions of Jira.
2. Jira via Connect - This integration uses an Add-on that is installed into your Jira instance by an administrator. It can only be used with Jira cloud and is restricted to integration with a single Jira server.


## Aha! to Jira workflow
Aha! is for the "why" and "what" and Jira is for the "how."
Do your product strategy, roadmapping, and feature definition in Aha! and push the items to Jira for engineering to build.
Aha! comes first and Jira second. We then keep the features up-to-date in Aha! as engineering does their work. 

## Integration functionality

The Jira integration is our most robust development tool integration. For a successful integration, it is very important to understand that the [integration workflow](http://support.aha.io/hc/en-us/articles/202001127) is based off of starting in Aha!

This integration supports sending the following items:

<table class='record-table'>
  <thead>
    <tr>
      <th>Two Way Integration</th>

      <th>One Way (Aha! to Jira)</th>

      <th>One Way (Jira to Aha!)</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td valign="top">
        <ul>
          <li>Feature name</li>

          <li>Feature description</li>

          <li>Requirements</li>

          <li>Assignee</li>

          <li>Reporter</li>

          <li>Attachments</li>

          <li>Tags (if enabled)</li>

          <li>Initiatives (if enabled)</li>

          <li>Feature due dates</li>

          <li>Estimates (if configured)</li>

          <li><a href="http://support.aha.io/hc/en-us/articles/206934573">Custom fields</a></li>

          <li>Comments</li>
        </ul>
      </td>

      <td valign="top">
        <ul>
          <li>Release name</li>

          <li>Release date</li>

          <li><a href="http://support.aha.io/hc/en-us/articles/204755559">Aha! Rank</a></li>
        </ul>
      </td>

      <td valign="top">
        <ul>
          <li>Status updates</li>
        </ul>
      </td>
    </tr>
  </tbody>
</table>
<br/>

Depending on whether you are using Jira Agile or standard Agile, below are details regarding feature mapping:

- If you use Jira Agile, [read this for feature mapping](http://support.aha.io/entries/40551483)
- If you use Jira, [read this for feature mapping](http://support.aha.io/entries/40843667)

There is also a set of advanced functionality unique to the Jira integration, such as the ability to have content created in Jira populate into Aha! automatically. Read more [here](https://support.aha.io/hc/en-us/articles/204452355-Advanced-Jira-functionality).

## Integration configuration

You need to be a Product Owner in Aha! and an Administrator in Jira to set up this integration. If you have already configured an integration that you wish to use as a [template](http://support.aha.io/hc/en-us/articles/210385463), you can skip these steps and simply apply your template through the Actions menu.

This integration works with both the cloud and on premise versions of Jira. If you are running the on premise version of Jira you will need to create a [firewall exception](http://support.aha.io/entries/40842777) so Aha! can make calls to the Jira API. The exception should forward requests to the internal Jira server.

Please carefully follow these instructions to ensure that the integration is properly configured.

1. Configure the Server URL, Username and Password below. After May 2017 [you may need to use your email address rather than username](https://confluence.atlassian.com/cloud/the-upgrade-to-atlassian-account-873871204.html#TheupgradetoAtlassianaccount-RESTAPIs) if you are using Jira Cloud. In this case your email address must be *verified* in Jira for the integration to work.
2. Click the _Test connection_ button
3. After a short delay, you will be able to choose the Project the issues will be created in.
4. Select the Jira project you wish to connect to and click _Load project data_.
5. Map how you want new features to show up in Jira and how the Jira status fields should map to Aha!
6. Copy the Webhook URL below, this step is required for the integration to be bi-directional.
7. In Jira, navigate to System Settings -> WebHooks.
8. Create a new Webhook in Jira and paste in the Webhook URL that you copied from step #6. Check the boxes for all _Worklog_ and _Issue_ events, do not check the box for _Exclude body._
9. Save the Webhook.
10. Enable the integration in Aha!
11. Test the integration by going to one of your features in Aha! and using the _Send to Jira_ item in the _Actions_ menu on the features page. You should then look at your project in Jira and see that the feature (and any requirements) were properly created.

## Troubleshooting

We have a support section dedicated to [troubleshooting the Jira integration.](http://support.aha.io/hc/en-us/sections/201102925) If you run into an error, we recommend you take a look at the logs below and search the support site. Almost every Jira integration error has a documented solution. If you cannot solve the issue please reach out to our team at  [support@aha.io](mailto:support@aha.io), we will be happy to help get your integration up and running!

A few common issues and their answers are below:

- [Updates from Jira are not being reflected in Aha!](http://support.aha.io/hc/en-us/articles/204700139)
- [Why is an Aha! field not being sent to Jira?](http://support.aha.io/hc/en-us/articles/204837595)
- [Do I need to add multiple webhooks to Jira?](http://support.aha.io/hc/en-us/articles/206582153)
- [Event ‘installed’ failed due to an unhandled error](http://support.aha.io/hc/en-us/articles/205401465)
