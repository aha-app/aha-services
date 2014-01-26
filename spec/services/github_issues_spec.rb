require 'spec_helper'

describe AhaServices::GithubIssues do
  let(:protocol) { 'https' }
  let(:domain) { 'api.github.com' }
  let(:username) { 'user' }
  let(:password) { 'secret' }
  let(:base_request_url) { "#{protocol}://#{username}:#{password}@#{domain}" }
  let(:service) do
    AhaServices::GithubIssues.new 'server_url' => "#{protocol}://#{domain}",
                                  'username' => username, 'password' => password
  end

  context "can be installed" do
    it "and handles installed event" do
      mock_repos = [ { name: 'First repo' } ]
      service.should_receive(:github_repos)
        .and_return(mock_repos)
      service.receive(:installed)
      expect(service.meta_data.repos.first)
        .to eq Hashie::Mash.new(mock_repos.first)
    end
  end

  it "handles the 'create release' event" do
    mock_payload = Hashie::Mash.new({ release: { name: "First release" } })
    service.stub(:payload).and_return(mock_payload)
    service.should_receive(:get_or_create_github_milestone)
      .with(mock_payload.release)
    service.receive(:create_release)
  end

  describe "#repos" do
    it "returns repos received from Github" do
      mock_repos = raw_fixture('github_issues/repos.json')
      stub_request(:get, "#{base_request_url}/user/repos").
        to_return(status: 200, body: mock_repos)
      expect(service.send(:github_repos)).to eq JSON.parse(mock_repos)
    end
  end
end
