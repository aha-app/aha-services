require 'spec_helper'

describe AhaServices::Jira do
  it "can receive new features" do
    # Call to Jira
    stub_request(:post, "http://u:p@foo.com/a/rest/api/2/issue").
      to_return(:status => 201, :body => "{\"id\":\"10009\",\"key\":\"DEMO-10\",\"self\":\"https://myhost.atlassian.net/rest/api/2/issue/10009\"}", :headers => {})
    # Add attachments.
    stub_request(:post, "http://u:p@foo.com/a/rest/api/2/issue/10009/attachments").
      to_return(:status => 200)
    
    # Call back into Aha! for feature
    stub_request(:post, "https://a.aha.io/api/v1/features/PROD-2/integrations/jira/fields").
      with(:body => {:integration_field => {:name => "id", :value => "10009"}}).
      to_return(:status => 201, :body => "", :headers => {})
    stub_request(:post, "https://a.aha.io/api/v1/features/PROD-2/integrations/jira/fields").
      with(:body => {:integration_field => {:name => "key", :value => "DEMO-10"}}).
      to_return(:status => 201, :body => "", :headers => {})
    stub_request(:post, "https://a.aha.io/api/v1/features/PROD-2/integrations/jira/fields").
      with(:body => {:integration_field => {:name => "url", :value => "http://foo.com/a/browse/DEMO-10"}}).
      to_return(:status => 201, :body => "", :headers => {})
    # Call back into Aha! for requirement
    stub_request(:post, "https://a.aha.io/api/v1/requirements/PROD-2-1/integrations/jira/fields").
      with(:body => {:integration_field => {:name => "id", :value => "10009"}}).
      to_return(:status => 201, :body => "", :headers => {})
    stub_request(:post, "https://a.aha.io/api/v1/requirements/PROD-2-1/integrations/jira/fields").
      with(:body => {:integration_field => {:name => "key", :value => "DEMO-10"}}).
      to_return(:status => 201, :body => "", :headers => {})
    stub_request(:post, "https://a.aha.io/api/v1/requirements/PROD-2-1/integrations/jira/fields").
      with(:body => {:integration_field => {:name => "url", :value => "http://foo.com/a/browse/DEMO-10"}}).
      to_return(:status => 201, :body => "", :headers => {})
    
    # Download attachments.
    stub_request(:get, "https://attachments.s3.amazonaws.com/attachments/6cce987f6283d15c080e53bba15b1072a7ab5b07/original.png?1370457053").
      to_return(:status => 200, :body => "aaaaaa", :headers => {})
    stub_request(:get, "https://attachments.s3.amazonaws.com/attachments/d1cb788065a70dad7ba481c973e19dcd379eb202/original.png?1370457055").
      to_return(:status => 200, :body => "bbbbbb", :headers => {})
    stub_request(:get, "https://attachments.s3.amazonaws.com/attachments/80641a3d3141ce853ea8642bb6324534fafef5b3/original.png?1370458143").
      to_return(:status => 200, :body => "cccccc", :headers => {})
    stub_request(:get, "https://attachments.s3.amazonaws.com/attachments/6fad2068e2aa0e031643d289367263d3721c8683/original.png?1370458145").
      to_return(:status => 200, :body => "dddddd", :headers => {})
        
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