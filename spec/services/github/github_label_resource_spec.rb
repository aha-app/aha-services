require 'spec_helper'

describe GithubIssueResource do
  let(:protocol) { 'https' }
  let(:domain) { 'api.github.com' }
  let(:username) { 'user' }
  let(:password) { 'secret' }
  let(:repo) { 'my_repo' }
  let(:base_request_url) do
    "#{protocol}://#{username}:#{password}@#{domain}/repos/#{username}/#{repo}/issues"
  end
  let(:service) do
    AhaServices::GithubIssues.new 'server_url' => "#{protocol}://#{domain}",
                                  'username' => username, 'password' => password,
                                  'repository' => repo
  end
  let(:label_resource) { GithubLabelResource.new(service) }

  describe "#update" do
    it "sends the updated label list to the api" do
      number = 42
      mock_labels_json = '[{ "name": "First label" }]'
      stub_request(:put, "#{base_request_url}/#{number}/labels")
        .to_return(status: 200, body: mock_labels_json)
      expect(label_resource.update(number, [{ name: "First label" }]))
        .to eq JSON.parse(mock_labels_json)
    end
  end
end
