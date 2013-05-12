aha-services
============

Service hooks interface based on Github-Services.



    bundle exec ruby -r ./config/load.rb -e "Service::Jira.new(:push, {'foo' => 'bar'}).receive_create_feature"