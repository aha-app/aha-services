require 'spec_helper'

describe AhaServices::GithubCommitHook do
  it "can create comments" do
    # Call into Aha!
    stub_request(:post, "https://a.aha.io/api/v1/features/SCRATCH-34/comments").
      with(:body => {:comment => {:body => /committed/}}).
      to_return(:status => 201, :body => "", :headers => {})
    stub_request(:post, "https://a.aha.io/api/v1/features/AA-12/comments").
      with(:body => {:comment => {:body => /committed/}}).
      to_return(:status => 201, :body => "", :headers => {})
    stub_request(:post, "https://a.aha.io/api/v1/requirements/BB-13-1/comments").
      with(:body => {:comment => {:body => /committed/}}).
      to_return(:status => 201, :body => "", :headers => {})
      
    AhaServices::GithubCommitHook.new(:webhook,
      {},json_fixture('github_commit_hook_webhook.json')).receive
  end
  
  it "silently ignores invalid references" do
    # Call into Aha!
    stub_request(:post, //).
      to_return(:status => 404, :body => "", :headers => {})
      
    AhaServices::GithubCommitHook.new(:webhook,
      {},json_fixture('github_commit_hook_webhook.json')).receive
  end
  
end