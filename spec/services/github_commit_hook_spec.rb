require 'spec_helper'

describe AhaServices::GithubCommitHook do
  it "can create comments" do
    # Call into Aha!
    stub_request(:post, "https://a.aha.io/api/v1/features/OPS-11/comments").
      with(:body => {:integration_field => {:name => "id", :value => "10009"}}).
      to_return(:status => 201, :body => "", :headers => {})
      
    AhaServices::GithubCommitHook.new(:webhook,
      {},json_fixture('github_commit_hook_webhook.json')).receive
  end
  
end