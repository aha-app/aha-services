aha-services
============

Service hooks interface based on Github-Services.


Running from the command line
-----------------------------

    bundle exec ruby -r ./config/load.rb -e "AhaServices::Jira.new(:create_feature, {'server_url' => 'https://watersco.atlassian.net', 'username' => 'u', 'password' => 'p', 'api_version' => '2'}, JSON.parse(File.new('spec/fixtures/create_feature_event.json').read)).receive"
    