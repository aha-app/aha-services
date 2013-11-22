require 'spec_helper'

describe AhaServices::PivotalTracker do
  before(:all) do
    @api_url = 'https://www.pivotaltracker.com/services/v5'

    @api_token = 'token'
    @project_id = '202020'

    @pivot_data = {
      story_id: '61280364',
      story_url: 'http://www.pivotaltracker.com/story/show/61017898',
      task_one_id: '18669866'
    }
  end

  it "can receive new features" do

    # PivotalTracker api v5
    stub_request(:post, '%s/projects/%s/stories' % [@api_url, @project_id]).
      to_return(:status => 200, :body => "{\"id\":\"#{@pivot_data[:story_id]}\",\"url\":\"#{@pivot_data[:story_url]}\"}", :headers => {})

    stub_request(:post, '%s/projects/%s/stories/%s/tasks' % [@api_url, @project_id, @pivot_data[:story_id]]).
      to_return(:status => 200, :body => "{\"id\":\"#{@pivot_data[:task_one_id]}\"}", :headers => {})

    # Call back into Aha! for feature
    stub_request(:post, "https://a.aha.io/api/v1/features/PROD-2/integrations/pivotal_tracker/fields").
      with(:body => {:integration_field => {:name => "id", :value => "#{@pivot_data[:story_id]}"}}).
      to_return(:status => 201, :body => "", :headers => {})
    stub_request(:post, "https://a.aha.io/api/v1/features/PROD-2/integrations/pivotal_tracker/fields").
      with(:body => {:integration_field => {:name => "url", :value => "#{@pivot_data[:story_url]}"}}).
      to_return(:status => 201, :body => "", :headers => {})

    # Call back into Aha! for requirement
    stub_request(:post, "https://a.aha.io/api/v1/requirements/PROD-2-1/integrations/pivotal_tracker/fields").
      with(:body => {:integration_field => {:name => "id", :value => "#{@pivot_data[:task_one_id]}"}}).
      to_return(:status => 201, :body => "", :headers => {})

    # run service
    AhaServices::PivotalTracker.new(:create_feature,
      {'api_token' => @api_token, 'project' => @project_id, 'api_version' => 'a'},
      json_fixture('create_feature_event.json')).receive
  end

  it "can update existing features" do

    # Call to PivotalTracker
    stub_request(:put, '%s/projects/%s/stories/%s' % [@api_url, @project_id, @pivot_data[:story_id]]).
      to_return(:status => 200, :body => "{}", :headers => {})
    stub_request(:put, '%s/projects/%s/stories/%s/tasks/%s' % [@api_url, @project_id, @pivot_data[:story_id], @pivot_data[:task_one_id]]).
      to_return(:status => 200, :body => "{}", :headers => {})

    AhaServices::PivotalTracker.new(:update_feature,
      {'api_token' => @api_token, 'project' => @project_id, 'api_version' => 'a'},
      json_fixture('update_feature_event.json')).receive
  end

  it "raises error when PivotalTracker fails" do

    stub_request(:post, '%s/projects/%s/stories' % [@api_url, @project_id]).
      to_return(:status => 401, :body => raw_fixture('pivotal_tracker/invalid_parameter.json'), :headers => {})
    expect {
      AhaServices::PivotalTracker.new(:create_feature,
        {'api_token' => @api_token, 'project' => @project_id, 'api_version' => 'a'},
        json_fixture('create_feature_event.json')).receive
    }.to raise_error(AhaService::RemoteError)
  end

  it "raises authentication error" do

    stub_request(:post, '%s/projects/%s/stories' % [@api_url, @project_id]).
      to_return(:status => 401, :body => raw_fixture('pivotal_tracker/auth_error.json'), :headers => {})

    expect {
      # run service
      AhaServices::PivotalTracker.new(:create_feature,
        {'api_token' => '', 'project' => @project_id, 'api_version' => 'a'},
        json_fixture('create_feature_event.json')).receive
    }.to raise_error(AhaService::RemoteError)
  end

  context "can be installed" do

    it "handles installed event" do

      stub_request(:get, '%s/projects' % [@api_url]).
        to_return(:status => 200, :body => raw_fixture('pivotal_tracker/projects.json'), :headers => {})


      service = AhaServices::PivotalTracker.new(:installed,
        {'api_token' => @api_token, 'api_version' => 'a'},
        nil)
      service.receive
      service.meta_data.projects[0]["name"].should == "Learn About the Force"
      service.meta_data.projects[0]["id"].should == 98
    end

  end

end