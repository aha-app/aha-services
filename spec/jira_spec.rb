require 'spec_helper'

describe "Service::Jira" do
  before do
    #@stubs = Faraday::Adapter::Test::Stubs.new
  end

  it "can receive new features" do
    stub_request(:post, "http://u:p@foo.com/a/rest/api/a/issue").
      #with(:body => hash_including({:fields => {:summary => "Strange name"}})#,
        #:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/json', 'User-Agent'=>'Faraday v0.8.7'}
      #  ).
      to_return(:status => 201, :body => "{\"id\":\"10009\",\"key\":\"DEMO-10\",\"self\":\"https://watersco.atlassian.net/rest/api/2/issue/10009\"}", :headers => {})

    svc = service(Service::Jira, 
      {'server_url' => 'http://foo.com/a', 'username' => 'u', 'password' => 'p', 'api_version' => 'a'},
      json_fixture('feature_event.json'))
    svc.receive_create_feature
  end
  
end