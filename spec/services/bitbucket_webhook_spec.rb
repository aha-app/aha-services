require "spec_helper"

describe AhaServices::BitbucketCommitHook do
  it "should process commit hooks" do
    stub_request(:post, /.*/).to_return(status: 404, body: "", headers: {})

    AhaServices::BitbucketCommitHook.new({}, {
      "payload" => JSON.parse(fixture("bitbucket_commit_hook/bitbucket_commit_hook_webhook.json").read)
    }).receive(:webhook)
  end
end
