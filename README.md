Aha! to third-party service integrations
========================================

This library provides integrations between Aha! and third-party services in response to user interface events within Aha! It is based on the [Github-Services](https://github.com/github/github-services) library.

Each third-party service is represented by at least three files:

1. Implementation of the integration in `lib/services/<service-name>.rb`.
2. User documentation for configuring and using the integration in `docs/<service-name>.md`.
3. Unit test for the integration in `spec/servces/<service-name>_spec.rb`.

To add support for a new service, add these three files then submit a pull request.

Service events
--------------

Service code is called in response to events triggered by the Aha! user interface. Each event is accompanied by a ruby hash `payload` that describes the particular event in detail. The possible events are:

* `installed` - occurs when the service is installed by an Aha! user. This event can be triggered by the _Test connection_ button in the Aha! integrations UI, but may also occur at other times. The event may occur many times for a service and must be idempotent. There is no payload.
* `create_feature` - occurs when a user chooses _Send to <service name>_ in the Aha! UI and no integration fields exist for the feature. The payload contains complete information about the feature. See [spec/fixtures/create_feature_event.json](spec/fixtures/create_feature_event.json) for an example.
* `update_feature` - occurs when a user chooses _Update to <service name>_ in the Aha! UI and integration fields already exist for the feature. The payload contains complete information about the feature. See [spec/fixtures/update_feature_event.json](spec/fixtures/update_feature_event.json) for an example.
* `create_feature` - occurs before `create_feature` if there are no integration fields for the release the feature belongs to. The payload contains complete information about the release. See [spec/fixtures/update_release_event.json](spec/fixtures/update_release_event.json) for an example.
* `update_feature` - occurs when there are changes to a release which has integration fields. The payload contains complete information about the release. See [spec/fixtures/update_release_event.json](spec/fixtures/update_release_event.json) for an example.
* `webhook` - occurs when a POST call to a webhook is received by Aha! The payload contains the body of the POST.

Configuration
-------------

Each service has two types of configuration information, each persistently stored and available via a Hashie mash. Each mash can store Ruby scalar values `String`, `Symbol`, `Numeric`, `NilClass`, `TrueClass`, `FalseClass`, `Date`, `Time`, `DateTime` as well as `Array` and `Hash`, but should not be used for other objects.

* `meta_data` - this mash is solely for the use of the integration to store any configuration information it needs to persist between events.
* `data` - this mash stores the user entered configuration information, corresponding to the fields in the Integrations user interface. It should not be modified by the integration code.

Integration fields
------------------

Each Aha! release, feature and requirement can have _integration fields_ which track the relationship between that object and an integration. It is up to the integration implementation to decide how to use the integration fields, Aha! simply provides a key/value store.

When an object is created in a third party system, the integration code can use the [Aha! API](http://www.aha.io/api) to store integration fields for the object.


Running from the command line
-----------------------------

An integration can be triggered from the command line during testing. Here is an example:

    bundle exec ruby -r ./config/load.rb -e "AhaServices::Jira.new( 
      {'server_url' => 'https://watersco.atlassian.net', 
        'username' => 'u', 
        'password' => 'p', 
        'api_version' => '2'},
      JSON.parse(File.new('spec/fixtures/create_feature_event.json').read)).receive(:create_feature)"
    