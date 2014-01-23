require 'spec_helper'

describe AhaServices::GithubIssues do
  context "can be installed" do
    let(:protocol) { 'https' }
    let(:domain) { 'api.github.com' }
    let(:username) { 'user' }
    let(:password) { 'secret' }
    let(:base_request_url) { "#{protocol}://#{username}:#{password}@#{domain}" }
    let(:service) do
      AhaServices::GithubIssues.new 'server_url' => "#{protocol}://#{domain}",
                                    'username' => username, 'password' => password
    end
    it "and handles installed event" do
      stub_request(:get, "#{base_request_url}/user/repos").
        to_return(status: 200, body: raw_fixture('github_issues/repos.json'))
      service.receive(:installed)
      expect(service.meta_data.repos[0]['name']).to eq 'getting_started_balloons'
    end
  end
end
