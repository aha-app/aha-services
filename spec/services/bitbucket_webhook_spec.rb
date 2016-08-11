require "spec_helper"

describe AhaServices::BitbucketCommitHook do
  it "should process commit hooks" do
    comment_request = nil
    stub_request(:post, /.*/)
      .with {|request| comment_request = request }
      .to_return(status: 404, body: "", headers: {})

    AhaServices::BitbucketCommitHook.new(
      {},
      JSON.parse(fixture("bitbucket_commit_hook/bitbucket_commit_hook_webhook.json").read)
    ).receive(:webhook)

    expect(comment_request.uri.path).to eq("/api/v1/features/ALEX-163/comments")
    expect(JSON.parse(comment_request.body)["comment"]["body"]).to match(/Alex Bartlow committed/)
  end
end
