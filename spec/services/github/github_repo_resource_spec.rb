require 'spec_helper'

describe GithubRepoResource do
  let(:protocol) { 'https' }
  let(:domain) { 'api.github.com' }
  let(:username) { 'user' }
  let(:password) { 'secret' }
  let(:base_request_url) { "#{protocol}://#{username}:#{password}@#{domain}" }
  let(:service) do
    AhaServices::GithubIssues.new 'server_url' => "#{protocol}://#{domain}",
                                  'username' => username, 'password' => password
  end
  let(:repo_resource) { GithubRepoResource.new(service) }
  describe "#all" do
    it "returns repos received from Github" do
      mock_repos = raw_fixture('github_issues/repos.json')
      mock_orgs = raw_fixture('github_issues/orgs.json')
      stub_request(:get, "#{base_request_url}/user/repos?per_page=100&page=1").
        to_return(status: 200, body: mock_repos)
      stub_request(:get, "#{base_request_url}/user/orgs?per_page=100&page=1").
        to_return(status: 200, body: mock_orgs)
      stub_request(:get, "#{base_request_url}/orgs/github/repos?per_page=100&page=1").
        to_return(status: 200, body: "[]")
      expect(repo_resource.all).to eq JSON.parse(mock_repos)
    end
  end
end
