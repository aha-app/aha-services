This bi-directional integration for both on premise and cloud versions of JIRA allows you to push features and requirements from Aha! into JIRA.

Note there are two separate integrations with JIRA, we recommend that you use the "JIRA" integration over the JIRA via Connect option.

1. JIRA (RECOMMENDED) - This integration uses the username and password of a JIRA user to authenticate with JIRA. It can be used with on premise or cloud versions of JIRA.
2. JIRA via Connect - This integration uses an Add-on that is installed into your JIRA instance by an administrator. It can only be used with JIRA cloud and is restricted to integration with a single JIRA server.

## Integration functionality

The JIRA integration is our most robust development tool integration. For a successful integration, it is very important to understand that the [integration workflow](http://support.aha.io/hc/en-us/articles/202001127) is based off of starting in Aha!

This integration supports sending the following items:

<table>
  <tr>
    <th>Two Way Integration</th>

    <th>One Way (Aha! to JIRA)</th>

    <th>One Way (JIRA to Aha!)</th>
  </tr>

  <tr>
    <td>
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

    <td>
      <ul>
        <li>Release name</li>

        <li>Release date</li>

        <li><a href="http://support.aha.io/hc/en-us/articles/204755559">Aha! Rank</a></li>
      </ul>
    </td>

    <td>
      <ul>
        <li>Status updates</li>
      </ul>
    </td>
  </tr>
</table>

The table summary attribute should be used to describe
the table structure. It is very helpful for people using
non-visual browsers. The scope and headers attributes for
table cells are useful for specifying which headers apply
to each table cell, enabling non-visual browsers to provide
a meaningful context for each cell.

For further advice on how to make your pages accessible
see http://www.w3.org/WAI/GL. You may also want to try
"http://www.cast.org/bobby/" which is a free Web-based
service for checking URLs for accessibility.

To learn more about HTML Tidy see http://tidy.sourceforge.net
Please send bug reports to html-tidy@w3.org
HTML and CSS specifications are available from http://www.w3.org/
Lobby your company to join W3C, see http://www.w3.org/Consortium

There is also a set of advanced functionality unique to the JIRA integration, such as the ability to have content created in JIRA populate into Aha! automatically. Read more [here](http://support.aha.io/hc/en-us/articles/204452355).

## Integration configuration

You need to be a Product Owner in Aha! and an Administrator in JIRA to set up this integration. If you have already configured an integration that you wish to use as a [template](http://support.aha.io/hc/en-us/articles/210385463), you can skip these steps and simply apply your template through the Actions menu.

This integration works with both the cloud and on premise versions of JIRA. If you are running the on premise version of JIRA you will need to create a [firewall exception](http://support.aha.io/entries/40842777) so Aha! can make calls to the JIRA API. The exception should forward requests to the internal JIRA server.

Please carefully follow these instructions to ensure that the integration is properly configured.

1. Configure the Server URL, Username and Password below. Click the _Test connection_ button
2. After a short delay, you will be able to choose the Project the issues will be created in.
3. Select the JIRA project you wish to connect to and click _Load project data_.
4. Map how you want new features to show up in JIRA and how the JIRA status fields should map to Aha!
5. Copy the Webhook URL below, this step is required for the integration to be bi-directional.
6. In JIRA, navigate to System Settings -> WebHooks.
7. Create a new Webhook in JIRA and paste in the Webhook URL that you copied from step #5. Check the boxes for all _Worklog_ and _Issue_ events, do not check the box for _Exclude body._
8. Save the Webhook.
9. Enable the integration in Aha!
10. Test the integration by going to one of your features in Aha! and using the _Send to JIRA_ item in the _Actions_ menu on the features page. You should then look at your project in JIRA and see that the feature (and any requirements) were properly created.

## Troubleshooting

We have a support section dedicated to [troubleshooting the JIRA integration.](http://support.aha.io/hc/en-us/sections/201102925) If you run into an error, we recommend you take a look at the logs below and search the support site. Almost every JIRA integration error has a documented solution. If you cannot solve the issue please reach out to our team at  [support@aha.io](mailto:support@aha.io), we will be happy to help get your integration up and running!

A few common issues and their answers are below:

- [Updates from JIRA are not being reflected in Aha!](http://support.aha.io/hc/en-us/articles/204700139)
- [Why is an Aha! field not being sent to JIRA?](http://support.aha.io/hc/en-us/articles/204837595)
- [Do I need to add multiple webhooks to JIRA?](http://support.aha.io/hc/en-us/articles/206582153)
- [Event ‘installed’ failed due to an unhandled error](http://support.aha.io/hc/en-us/articles/205401466)
