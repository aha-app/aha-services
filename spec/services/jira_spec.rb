require 'spec_helper'

describe AhaServices::Jira do
  it "can receive new features" do
    # Call to Jira
    stub_request(:post, "http://u:p@foo.com/a/rest/api/2/issue").
      #with(:body => hash_including({:fields => {:summary => "Strange name"}})#,
        #:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/json', 'User-Agent'=>'Faraday v0.8.7'}
      #  ).
      to_return(:status => 201, :body => "{\"id\":\"10009\",\"key\":\"DEMO-10\",\"self\":\"https://myhost.atlassian.net/rest/api/2/issue/10009\"}", :headers => {})
    
    # Call back into Aha!
    stub_request(:post, "https://a.aha.io/api/v1/features/OPS-11/integrations/jira/fields").
      with(:body => {:integration_field => {:name => "id", :value => "10009"}}).
      to_return(:status => 201, :body => "", :headers => {})
    stub_request(:post, "https://a.aha.io/api/v1/features/OPS-11/integrations/jira/fields").
      with(:body => {:integration_field => {:name => "key", :value => "DEMO-10"}}).
      to_return(:status => 201, :body => "", :headers => {})
      stub_request(:post, "https://a.aha.io/api/v1/features/OPS-11/integrations/jira/fields").
        with(:body => {:integration_field => {:name => "url", :value => "http://foo.com/a/browse/DEMO-10"}}).
        to_return(:status => 201, :body => "", :headers => {})
      
    AhaServices::Jira.new(:create_feature,
      {'server_url' => 'http://foo.com/a', 'username' => 'u', 'password' => 'p'},
      json_fixture('feature_event.json')).receive
  end
  
  it "raises error when Jira fails" do
    stub_request(:post, "http://u:p@foo.com/a/rest/api/2/issue").
      to_return(:status => 400, :body => "{\"errorMessages\":[],\"errors\":{\"description\":\"Operation value must be a string\"}}", :headers => {})
    expect {
      AhaServices::Jira.new(:create_feature,
        {'server_url' => 'http://foo.com/a', 'username' => 'u', 'password' => 'p'},
        json_fixture('feature_event.json')).receive
    }.to raise_error(AhaService::RemoteError)
  end
  
  it "raises authentication error" do
    stub_request(:post, "http://u:p@foo.com/a/rest/api/2/issue").
      to_return(:status => 401, :body => "", :headers => {})
    expect {
      AhaServices::Jira.new(:create_feature,
        {'server_url' => 'http://foo.com/a', 'username' => 'u', 'password' => 'p'},
        json_fixture('feature_event.json')).receive
    }.to raise_error(AhaService::RemoteError)
  end
  
  context "can be installed" do
    
    it "handles installed event" do
      stub_request(:get, "http://u:p@foo.com/a/rest/api/2/issue/createmeta").
        to_return(:status => 200, :body => raw_fixture('jira_createmeta.json'), :headers => {})
      stub_request(:get, "http://u:p@foo.com/a/rest/api/2/project/APPJ/statuses").
        to_return(:status => 200, :body => raw_fixture('jira_project_statuses.json'), :headers => {})
      
      service = AhaServices::Jira.new(:installed,
        {'server_url' => 'http://foo.com/a', 'username' => 'u', 'password' => 'p', 'api_version' => 'a'},
        nil)
      service.receive
      service.meta_data.projects[0]["key"].should == "APPJ"
      service.meta_data.projects[0].issue_types[0].name.should == "Bug"     
      service.meta_data.projects[0].issue_types[0].statuses[0].name.should == "Open"     
    end
    
  end
  
end