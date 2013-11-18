require  File.expand_path("../../../config/load.rb", __FILE__)
require 'spec_helper'

describe AhaServices::Pivotaltracker do
  before(:all) do
    @api_url = 'https://www.pivotaltracker.com/services/v5'

    @api_token =  'token'
    @project_id = '202020'

    @pivot_data = {
        story_id: '60958942',
        story_url: 'http://www.pivotaltracker.com/story/show/60958942',
        task_one_id: '783939234'
    }
  end

  it "can receive new features" do

    # Pivotaltracker api v5
    stub_request(:post, '%s/projects/%s/stories' % [@api_url, @project_id]).
        to_return(:status => 200, :body => "{\"id\":\"#{@pivot_data[:story_id]}\",\"url\":\"#{@pivot_data[:story_url]}\"}", :headers => {})

    stub_request(:post, '%s/projects/%s/stories/%s/tasks' % [@api_url, @project_id, @pivot_data[:story_id]]).
        to_return(:status => 200, :body => "{\"id\":\"#{@pivot_data[:task_one_id]}\"}", :headers => {})

    # Call back into Aha! for feature
    stub_request(:post, "https://a.aha.io/api/v1/features/PROD-2/integrations/pivotaltracker/fields").
        with(:body => {:integration_field => {:name => "id", :value => "#{@pivot_data[:story_id]}"}}).
        to_return(:status => 201, :body => "", :headers => {})
    stub_request(:post, "https://a.aha.io/api/v1/features/PROD-2/integrations/pivotaltracker/fields").
        with(:body => {:integration_field => {:name => "url", :value => "#{@pivot_data[:story_url]}"}}).
        to_return(:status => 201, :body => "", :headers => {})

    # Call back into Aha! for requirement
    stub_request(:post, "https://a.aha.io/api/v1/requirements/PROD-2-1/integrations/pivotaltracker/fields").
        with(:body => {:integration_field => {:name => "id", :value => "#{@pivot_data[:task_one_id]}"}}).
        to_return(:status => 201, :body => "", :headers => {})

    # run service
    AhaServices::Pivotaltracker.new(:create_feature,
      {'api_token' => @api_token, 'project' => @project_id},
      json_fixture('create_feature_event.json')).receive
  end

  it "can upate existing features" do

  end

  it "raises error when Pivotaltracker fails" do

  end

  it "raises authentication error" do

  end

  context "can be installed" do

    it "handles installed event" do

    end


  end

end