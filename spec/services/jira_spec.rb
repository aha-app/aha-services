require 'spec_helper'

describe AhaServices::Jira do
  let(:integration_data) { {'projects'=>[{'id'=>'10000', 'key'=>'DEMO', 'name'=>'Aha! App Development', 'issue_types'=>[{'id'=>'1', 'name'=>'Bug', 'subtask'=>false, 'statuses'=>[{'id'=>'1', 'name'=>'Open'}, {'id'=>'3', 'name'=>'In Progress'}, {'id'=>'5', 'name'=>'Resolved'}, {'id'=>'4', 'name'=>'Reopened'}, {'id'=>'6', 'name'=>'Closed'}]}, {'id'=>'2', 'name'=>'New Feature', 'subtask'=>false, 'statuses'=>[{'id'=>'1', 'name'=>'Open'}, {'id'=>'3', 'name'=>'In Progress'}, {'id'=>'5', 'name'=>'Resolved'}, {'id'=>'4', 'name'=>'Reopened'}, {'id'=>'6', 'name'=>'Closed'}]}, {'id'=>'3', 'name'=>'Task', 'subtask'=>false, 'statuses'=>[{'id'=>'1', 'name'=>'Open'}, {'id'=>'3', 'name'=>'In Progress'}, {'id'=>'5', 'name'=>'Resolved'}, {'id'=>'4', 'name'=>'Reopened'}, {'id'=>'6', 'name'=>'Closed'}]}, {'id'=>'4', 'name'=>'Improvement', 'subtask'=>false, 'statuses'=>[{'id'=>'1', 'name'=>'Open'}, {'id'=>'3', 'name'=>'In Progress'}, {'id'=>'5', 'name'=>'Resolved'}, {'id'=>'4', 'name'=>'Reopened'}, {'id'=>'6', 'name'=>'Closed'}]}, {'id'=>'5', 'name'=>'Sub-task', 'subtask'=>true, 'statuses'=>[{'id'=>'1', 'name'=>'Open'}, {'id'=>'3', 'name'=>'In Progress'}, {'id'=>'5', 'name'=>'Resolved'}, {'id'=>'4', 'name'=>'Reopened'}, {'id'=>'6', 'name'=>'Closed'}]}, {'id'=>'6', 'name'=>'Epic', 'subtask'=>false, 'statuses'=>[{'id'=>'1', 'name'=>'Open'}, {'id'=>'3', 'name'=>'In Progress'}, {'id'=>'5', 'name'=>'Resolved'}, {'id'=>'4', 'name'=>'Reopened'}, {'id'=>'6', 'name'=>'Closed'}]}, {'id'=>'7', 'name'=>'Story', 'subtask'=>false, 'statuses'=>[{'id'=>'1', 'name'=>'Open'}, {'id'=>'3', 'name'=>'In Progress'}, {'id'=>'5', 'name'=>'Resolved'}, {'id'=>'4', 'name'=>'Reopened'}, {'id'=>'6', 'name'=>'Closed'}]}, {'id'=>'8', 'name'=>'Technical task', 'subtask'=>true, 'statuses'=>[{'id'=>'1', 'name'=>'Open'}, {'id'=>'3', 'name'=>'In Progress'}, {'id'=>'5', 'name'=>'Resolved'}, {'id'=>'4', 'name'=>'Reopened'}, {'id'=>'6', 'name'=>'Closed'}]}]}]} }
  
  def stub_creating_version
    # Create version.
    stub_request(:get, "http://u:p@foo.com/a/rest/api/2/project/DEMO/versions").
      to_return(:status => 200, :body => "[]", :headers => {})
    stub_request(:post, "http://u:p@foo.com/a/rest/api/2/version").
      with(:body => "{\"name\":\"Summer\",\"description\":\"Created from Aha! \",\"releaseDate\":null,\"released\":null,\"project\":\"DEMO\"}").
      to_return(:status => 201, :body => "{\"id\":\"666\"}", :headers => {})
    # Call back into Aha! for release.
    stub_request(:post, "https://a.aha.io/api/v1/releases/PROD-R-1/integrations/jira/fields").
      with(:body => {:integration_field => {:name => "id", :value => "666"}}).
      to_return(:status => 201, :body => "", :headers => {})
  end
  
  it "can receive new features" do
    stub_creating_version
    
    # Call to Jira
    stub_request(:post, "http://u:p@foo.com/a/rest/api/2/issue").
      to_return(:status => 201, :body => "{\"id\":\"10009\",\"key\":\"DEMO-10\",\"self\":\"https://myhost.atlassian.net/rest/api/2/issue/10009\"}", :headers => {})
    # Add attachments.
    stub_request(:post, "http://u:p@foo.com/a/rest/api/2/issue/10009/attachments").
      to_return(:status => 200)
    # Link to requirement.
    stub_request(:post, "http://foo.com/a/rest/api/2/issueLink").
      with(:body => {"{\"type\":{\"name\":\"Relates\"},\"outwardIssue\":{\"id\":\"10009\"},\"inwardIssue\":{\"id\":\"10009\"}}"=>true}).
      to_return(:status => 201)
      
    # Call back into Aha! for feature
    stub_request(:post, "https://a.aha.io/api/v1/features/5886067808745625353/integrations/jira/fields").
      with(:body => {:integration_field => {:name => "id", :value => "10009"}}).
      to_return(:status => 201, :body => "", :headers => {})
    stub_request(:post, "https://a.aha.io/api/v1/features/5886067808745625353/integrations/jira/fields").
      with(:body => {:integration_field => {:name => "key", :value => "DEMO-10"}}).
      to_return(:status => 201, :body => "", :headers => {})
    stub_request(:post, "https://a.aha.io/api/v1/features/5886067808745625353/integrations/jira/fields").
      with(:body => {:integration_field => {:name => "url", :value => "http://foo.com/a/browse/DEMO-10"}}).
      to_return(:status => 201, :body => "", :headers => {})
    # Call back into Aha! for requirement
    stub_request(:post, "https://a.aha.io/api/v1/requirements/5886072825272941795/integrations/jira/fields").
      with(:body => {:integration_field => {:name => "id", :value => "10009"}}).
      to_return(:status => 201, :body => "", :headers => {})
    stub_request(:post, "https://a.aha.io/api/v1/requirements/5886072825272941795/integrations/jira/fields").
      with(:body => {:integration_field => {:name => "key", :value => "DEMO-10"}}).
      to_return(:status => 201, :body => "", :headers => {})
    stub_request(:post, "https://a.aha.io/api/v1/requirements/5886072825272941795/integrations/jira/fields").
      with(:body => {:integration_field => {:name => "url", :value => "http://foo.com/a/browse/DEMO-10"}}).
      to_return(:status => 201, :body => "", :headers => {})
    
    stub_download_feature_attachments
        
    AhaServices::Jira.new(
      {'server_url' => 'http://foo.com/a', 'username' => 'u', 'password' => 'p', 'project'=>'DEMO', 'feature_issue_type' =>'6'},
      json_fixture('create_feature_event.json'), integration_data).receive(:create_feature)
  end
  
  it "can update existing features" do
    # Verify release.
    stub_request(:get, "http://u:p@foo.com/a/rest/api/2/version/777").
      to_return(:status => 200, :body => "", :headers => {})
    
    # Call to Jira
    stub_request(:get, "http://u:p@foo.com/a/rest/api/2/issue/10009?fields=attachment").
      to_return(:status => 200, :body => raw_fixture('jira/jira_attachments.json'), :headers => {})
    stub_request(:put, "http://u:p@foo.com/a/rest/api/2/issue/10009").
      to_return(:status => 204, :body => "{\"fields\":{\"description\":\"\\n\\nCreated from Aha! [PROD-2|http://watersco.aha.io/features/PROD-2]\",\"summary\":\"Feature with attachments\"}}", :headers => {})
    
    stub_download_feature_attachments
      
    # Upload new attachments.
    stub_request(:post, "http://u:p@foo.com/a/rest/api/2/issue/10009/attachments").
      with(:body => "-------------RubyMultipartPost\r\nContent-Disposition: form-data; name=\"file\"; filename=\"Belgium.png\"\r\nContent-Length: 6\r\nContent-Type: image/png\r\nContent-Transfer-Encoding: binary\r\n\r\nbbbbbb\r\n-------------RubyMultipartPost--\r\n\r\n").
      to_return(:status => 200, :body => "", :headers => {})
    stub_request(:post, "http://u:p@foo.com/a/rest/api/2/issue/10009/attachments").
      with(:body => "-------------RubyMultipartPost\r\nContent-Disposition: form-data; name=\"file\"; filename=\"France.png\"\r\nContent-Length: 6\r\nContent-Type: image/png\r\nContent-Transfer-Encoding: binary\r\n\r\ndddddd\r\n-------------RubyMultipartPost--\r\n\r\n").
      to_return(:status => 200, :body => "", :headers => {})
  
  
    AhaServices::Jira.new(
      {'server_url' => 'http://foo.com/a', 'username' => 'u', 'password' => 'p', 'project'=>'DEMO'},
      json_fixture('update_feature_event.json'), integration_data).receive(:update_feature)
  end
  
  it "raises error when Jira fails" do
    stub_creating_version
    
    stub_request(:post, "http://u:p@foo.com/a/rest/api/2/issue").
      to_return(:status => 400, :body => "{\"errorMessages\":[],\"errors\":{\"description\":\"Operation value must be a string\"}}", :headers => {})
    expect {
      AhaServices::Jira.new(
        {'server_url' => 'http://foo.com/a', 'username' => 'u', 'password' => 'p', 'project'=>'DEMO', 'feature_issue_type' =>'6'},
        json_fixture('create_feature_event.json'), integration_data).receive(:create_feature)
    }.to raise_error(AhaService::RemoteError)
  end
  
  it "raises authentication error" do
    stub_creating_version
    
    stub_request(:post, "http://u:p@foo.com/a/rest/api/2/issue").
      to_return(:status => 401, :body => "", :headers => {})
    expect {
      AhaServices::Jira.new(
        {'server_url' => 'http://foo.com/a', 'username' => 'u', 'password' => 'p', 'project'=>'DEMO', 'feature_issue_type' =>'6'},
        json_fixture('create_feature_event.json'), integration_data).receive(:create_feature)
    }.to raise_error(AhaService::RemoteError)
  end
  
  context "releases" do
    it "can be updated" do
      stub_request(:put, "http://u:p@foo.com/a/rest/api/2/version/777").
        with(:body => "{\"name\":\"Production Web Hosting\",\"releaseDate\":\"2013-01-28\",\"released\":false,\"id\":\"777\"}").
        to_return(:status => 200, :body => "", :headers => {})
      
      AhaServices::Jira.new(
        {'server_url' => 'http://foo.com/a', 'username' => 'u', 'password' => 'p'},
        json_fixture('update_release_event.json')).receive(:update_release)
    end
    
    it "can handle version being deleted" do
    end
    
  end
  
  context "can be installed" do
    
    it "handles installed event" do
      stub_request(:get, "http://u:p@foo.com/a/rest/api/2/issue/createmeta").
        to_return(:status => 200, :body => raw_fixture('jira/jira_createmeta.json'), :headers => {})
      stub_request(:get, "http://u:p@foo.com/a/rest/api/2/project/APPJ/statuses").
        to_return(:status => 200, :body => raw_fixture('jira/jira_project_statuses.json'), :headers => {})
      stub_request(:get, "http://u:p@foo.com/a/rest/api/2/resolution").
        to_return(:status => 200, :body => raw_fixture('jira/jira_resolutions.json'), :headers => {})
      stub_request(:get, "http://u:p@foo.com/a/rest/api/2/field").
        to_return(:status => 200, :body => raw_fixture('jira/jira_field.json'), :headers => {})
      
      service = AhaServices::Jira.new(
        {'server_url' => 'http://foo.com/a', 'username' => 'u', 'password' => 'p', 'api_version' => 'a'},
        nil)
      service.receive(:installed)
      service.meta_data.projects[0]["key"].should == "APPJ"
      service.meta_data.projects[0].issue_types[0].name.should == "Bug"     
      service.meta_data.projects[0].issue_types[0].statuses[0].name.should == "Open"     
    end
    
    it "handles installed event for Jira 5.0" do
      stub_request(:get, "http://u:p@foo.com/a/rest/api/2/issue/createmeta").
        to_return(:status => 200, :body => raw_fixture('jira/jira_createmeta.json'), :headers => {})
      stub_request(:get, "http://u:p@foo.com/a/rest/api/2/project/APPJ/statuses").
        to_return(:status => 404, :headers => {})
      stub_request(:get, "http://u:p@foo.com/a/rest/api/2/status").
        to_return(:status => 200, :body => raw_fixture('jira/jira_status.json'), :headers => {})
      stub_request(:get, "http://u:p@foo.com/a/rest/api/2/resolution").
        to_return(:status => 200, :body => raw_fixture('jira/jira_resolutions.json'), :headers => {})
      stub_request(:get, "http://u:p@foo.com/a/rest/api/2/field").
        to_return(:status => 200, :body => raw_fixture('jira/jira_field.json'), :headers => {})
    
      service = AhaServices::Jira.new(
        {'server_url' => 'http://foo.com/a', 'username' => 'u', 'password' => 'p', 'api_version' => 'a'},
        nil)
      service.receive(:installed)
      service.meta_data.projects[0]["key"].should == "APPJ"
      service.meta_data.projects[0].issue_types[0].name.should == "Bug"     
      service.meta_data.projects[0].issue_types[0].statuses[0].name.should == "Open"     
    end
    
  end
  
end