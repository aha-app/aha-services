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
  
  it "processes with product prefixes with numbers" do
    comment_request = nil
    stub_request(:post, /.*/)
      .with {|request| comment_request = request }
      .to_return(status: 404, body: "", headers: {})
  
    AhaServices::BitbucketCommitHook.new(
      {},
      JSON.parse(fixture("bitbucket_commit_hook/bitbucket_commit_hook_webhook_numbers.json").read)
    ).receive(:webhook)
  
    expect(comment_request.uri.path).to eq("/api/v1/features/BIG2-163/comments")
    expect(JSON.parse(comment_request.body)["comment"]["body"]).to match(/Alex Bartlow committed/)
  end
  
  it "processes without an author email" do
    comment_request = nil
    stub_request(:post, /.*/)
      .with {|request| comment_request = request }
      .to_return(status: 404, body: "", headers: {})
  
    AhaServices::BitbucketCommitHook.new(
      {},
      JSON.parse(fixture("bitbucket_commit_hook/bitbucket_commit_hook_no_email.json").read)
    ).receive(:webhook)
  
    expect(comment_request.uri.path).to eq("/api/v1/features/ALEX-163/comments")
    expect(JSON.parse(comment_request.body)["comment"]["body"]).to match(/Alex Bartlow committed/)
  end
end
