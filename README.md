aha-services
============

Service hooks interface based on Github-Services.



    bundle exec ruby -r ./config/load.rb -e "Service::Jira.new(:create_feature, {'server_url' => 'https://watersco.atlassian.net/', 'username' => 'u', 'password' => 'p', 'api_version' => '2'}, {}).receive"