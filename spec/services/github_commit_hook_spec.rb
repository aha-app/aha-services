require 'spec_helper'

describe AhaServices::GithubCommitHook do
  it "can create comments" do
    # Call into Aha!
    stub_request(:post, "https://a.aha.io/api/v1/features/SCRATCH-34/comments").
      with(:body => {:comment => {:user_email => "lolwut@noway.biz", :body => /committed/}}).
      to_return(:status => 201, :body => "", :headers => {})
    stub_request(:post, "https://a.aha.io/api/v1/features/BIG-2/comments").
      with(:body => {:comment => {:user_email => "lolwut@noway.biz", :body => /committed/}}).
      to_return(:status => 201, :body => "", :headers => {})
    stub_request(:post, "https://a.aha.io/api/v1/requirements/BIG-2-1/comments").
      with(:body => {:comment => {:user_email => "lolwut@noway.biz", :body => /committed/}}).
      to_return(:status => 201, :body => "", :headers => {})
      
    AhaServices::GithubCommitHook.new(:webhook,
      {},{"payload" => fixture('github_commit_hook/github_commit_hook_webhook.json').read}).receive
  end
  
  it "silently ignores invalid references" do
    # Call into Aha!
    stub_request(:post, /.*/).
      to_return(:status => 404, :body => "", :headers => {})
      
    AhaServices::GithubCommitHook.new(:webhook,
      {},{"payload" => fixture('github_commit_hook/github_commit_hook_webhook.json').read}).receive
  end
  
end