Aha! to third-party service integrations
========================================

This library provides integrations between Aha! and third-party services in response to user interface events within Aha! It is based on the [Github-Services](https://github.com/github/github-services) library.

This library supports integrations written in Ruby.

Each third-party service is represented by at least three files:

1. Implementation of the integration in `lib/services/<service-name>.rb`.
2. User documentation for configuring and using the integration in `docs/<service-name>.md`.
3. Unit test for the integration in `spec/servces/<service-name>_spec.rb`.

To add support for a new service, add these three files then submit a pull request.

Contact [support@aha.io](mailto:support@aha.io) for help using this code.

Service events
--------------

This service code is called in response to events triggered by the Aha! user interface. Each event is accompanied by a `payload` that describes the particular event in detail. The possible events are:

* `installed` - occurs when the service is installed by an Aha! user. This event can be triggered by the _Test connection_ button in the Aha! integrations UI, but may also occur at other times. The event may occur many times for a service and must be idempotent. There is no payload.
* `create_feature` - occurs when a user chooses _Send to <service name>_ in the Aha! UI and no integration fields exist for the feature. The payload contains complete information about the feature. See [spec/fixtures/create_feature_event.json](spec/fixtures/create_feature_event.json) for an example.
* `update_feature` - occurs when a user chooses _Update to <service name>_ in the Aha! UI and integration fields already exist for the feature. The payload contains complete information about the feature. See [spec/fixtures/update_feature_event.json](spec/fixtures/update_feature_event.json) for an example.
* `create_release` - occurs before `create_feature` if there are no integration fields for the release the feature belongs to. The payload contains complete information about the release. See [spec/fixtures/update_release_event.json](spec/fixtures/update_release_event.json) for an example.
* `update_release` - occurs when there are changes to a release which has integration fields. The payload contains complete information about the release. See [spec/fixtures/update_release_event.json](spec/fixtures/update_release_event.json) for an example.
* `webhook` - occurs when a POST call to a webhook is received by Aha! The payload contains the body of the POST. This event can be used to make the integration bi-directional and react to changes happening in the integrated system.

Configuration
-------------

Each service has two types of configuration information, each persistently stored and available via a [Hashie::Mash](https://github.com/intridea/hashie). Each mash can store Ruby scalar values `String`, `Symbol`, `Numeric`, `NilClass`, `TrueClass`, `FalseClass`, `Date`, `Time`, `DateTime` as well as `Array` and `Hash`, but should not be used for other objects.

* `meta_data` - this mash is solely for the use of the integration to store any configuration information it needs to persist between events. Changes to
the meta_data will only be saved after the `installed` event.
* `data` - this mash stores the user entered configuration information, corresponding to the fields in the Integrations user interface. It should not be modified by the integration code.

Integration fields
------------------

Each Aha! release, feature and requirement can have _integration fields_ which track the relationship between that object and an integration. It is up to the integration implementation to decide how to use the integration fields, Aha! simply provides a key/value store that is per-record-per-integration.

When an object is created in a third party system, the integration code can use the [Aha! API](http://www.aha.io/api) to store integration fields for the object. A typical pattern is to store the integration fields like:

    api.create_integration_fields('features', feature.id, self.class.service_name,
      {id: issue.id, key: issue[:key]})

The payload for each feature and release event will contain the integration fields that have previously been set.

Running an integration in development
-------------------------------------

You can run the integration in development by using a proxy server running on your development machine that passes messages between Aha! and the service code. Your development machine must be accessible to the Internet so that Aha! can send messages to it asynchronously. One way to do this is using [ngrok](https://ngrok.com/).

The proxy works by sending HTTP messages from Aha! to your development machine
to get configuration and remotely access the service. This allows you to 
rapidly develop and troubleshoot the service code using data from your live
Aha! instance.

1. Run the proxy server on your local development machine:
  
    ```
    bundle
    ./bin/proxy_server
    ```
    
2. In another terminal window start a tunnel to your running proxy server so that Aha! can access it, e.g. using ngrok:

    ```
    ngrok 4567
    ```
    
3. Copy the HTTPS version of the `Forwarding address`, e.g.  `https://ba4a410.ngrok.com`.

4. You can test this URL by loading `https://ba4a410.ngrok.com/configuration` in your browser.

5. Make the special "Development Proxy" integration visible in the Aha! UI by
logging into your Aha! account and going to any existing integration. Add `?development=true` to the URL and load the page. You will see a new integration appear named "Development Proxy".

6. Configure the development proxy settings. After you enter the proxy server
URL go got in step 3 you will be able to choose from a list of the services
that are running on your local machine.

7. Send features and releases to the "Development Proxy" and they will be send to your remotely running code.

The proxy server must be stopped using Ctrl-C and restarted each time the code
changes.