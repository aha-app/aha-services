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
        #with(:body => hash_including({:fields => {:summary => "Strange name"}})#,
          #:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/json', 'User-Agent'=>'Faraday v0.8.7'}
        #  ).
        to_return(:status => 200, :body => "{\"expand\":\"projects\",\"projects\":[{\"self\":\"http://www.example.com/jira/rest/api/2/project/EX\",\"id\":\"10000\",\"key\":\"EX\",\"name\":\"ExampleProject\",\"avatarUrls\":{\"16x16\":\"http://www.example.com/jira/secure/projectavatar?size=small&pid=10000&avatarId=10011\",\"48x48\":\"http://www.example.com/jira/secure/projectavatar?pid=10000&avatarId=10011\"},\"issuetypes\":[{\"self\":\"http://www.example.com/jira/rest/api/2/issueType/1\",\"id\":\"1\",\"description\":\"Anerrorinthecode\",\"iconUrl\":\"http://www.example.com/jira/images/icons/issuetypes/bug.png\",\"name\":\"Bug\",\"subtask\":false,\"fields\":{\"issuetype\":{\"required\":true,\"name\":\"IssueType\",\"operations\":[\"set\"]}}}]}]}" , :headers => {})
      
      service = AhaServices::Jira.new(:installed,
        {'server_url' => 'http://foo.com/a', 'username' => 'u', 'password' => 'p', 'api_version' => 'a'},
        nil)
      service.receive
      service.meta_data.projects[0]["key"].should == "EX"
      service.meta_data.projects[0].issue_types[0].name.should == "Bug"     
    end
    
  end
  
end