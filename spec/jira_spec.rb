require 'spec_helper'

describe "Service::Jira" do
  it "can receive new features" do
    # Call to Jira
    stub_request(:post, "http://u:p@foo.com/a/rest/api/a/issue").
      #with(:body => hash_including({:fields => {:summary => "Strange name"}})#,
        #:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/json', 'User-Agent'=>'Faraday v0.8.7'}
      #  ).
      to_return(:status => 201, :body => "{\"id\":\"10009\",\"key\":\"DEMO-10\",\"self\":\"https://myhost.atlassian.net/rest/api/2/issue/10009\"}", :headers => {})
    
    # Call back into Aha!
    stub_request(:post, "https://a.aha.io/api/v1/features/OPS-11/connection/jira/fields").
      with(:body => "{\"name\":\"id\",\"value\":\"10009\"}").
      to_return(:status => 201, :body => "", :headers => {})
    stub_request(:post, "https://a.aha.io/api/v1/features/OPS-11/connection/jira/fields").
      with(:body => "{\"name\":\"key\",\"value\":\"DEMO-10\"}").
      to_return(:status => 201, :body => "", :headers => {})
      
    Service::Jira.new(:create_feature,
      {'server_url' => 'http://foo.com/a', 'username' => 'u', 'password' => 'p', 'api_version' => 'a'},
      json_fixture('feature_event.json')).receive
  end
  
  it "raises error when Jira fails" do
    stub_request(:post, "http://u:p@foo.com/a/rest/api/a/issue").
      to_return(:status => 400, :body => "{\"errorMessages\":[],\"errors\":{\"description\":\"Operation value must be a string\"}}", :headers => {})
    expect {
      Service::Jira.new(:create_feature,
        {'server_url' => 'http://foo.com/a', 'username' => 'u', 'password' => 'p', 'api_version' => 'a'},
        json_fixture('feature_event.json')).receive
    }.to raise_error(Service::RemoteError)
  end
  
  it "raises authentication error" do
    stub_request(:post, "http://u:p@foo.com/a/rest/api/a/issue").
      to_return(:status => 401, :body => "", :headers => {})
    expect {
      Service::Jira.new(:create_feature,
        {'server_url' => 'http://foo.com/a', 'username' => 'u', 'password' => 'p', 'api_version' => 'a'},
        json_fixture('feature_event.json')).receive
    }.to raise_error(Service::RemoteError)
  end
  
end