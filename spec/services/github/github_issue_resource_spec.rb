require 'spec_helper'

describe GithubIssueResource do
  let(:protocol) { 'https' }
  let(:domain) { 'api.github.com' }
  let(:username) { 'user' }
  let(:password) { 'secret' }
  let(:repo) { 'user/my_repo' }
  let(:base_request_url) do
    "#{protocol}://#{username}:#{password}@#{domain}/repos/#{repo}/issues"
  end
  let(:service) do
    AhaServices::GithubIssues.new 'server_url' => "#{protocol}://#{domain}",
                                  'username' => username, 'password' => password,
                                  'repository' => repo
  end
  let(:issue_resource) { GithubIssueResource.new(service) }
  let(:mock_issue_with_milestone) { raw_fixture('github_issues/issue_with_milestone.json') }
  let(:mock_issue_without_milestone) { raw_fixture('github_issues/issue_without_milestone.json') }
  let(:mock_milestone) { { 'number' => 1 } }


  describe "#find_by_number_and_milestone" do
    let(:number) { 42 }
    context "when an issue with such number doesn't exist" do
      it "returns nil" do
        stub_request(:get, "#{base_request_url}/#{number}")
          .to_return(status: 404)
        expect(issue_resource.find_by_number_and_milestone(number, mock_milestone))
          .to be_nil
      end
    end

    context "when an issue with such number exists" do
      context "when it doesn't have a milestone field" do
        it "returns nil" do
          stub_request(:get, "#{base_request_url}/#{number}")
            .to_return(status: 200, body: mock_issue_without_milestone)
          expect(issue_resource.find_by_number_and_milestone(number, mock_milestone))
            .to be_nil
        end
      end

      context "when its milestone is the same as the milestone in the parameter" do
        it "returns the issue" do
          stub_request(:get, "#{base_request_url}/#{number}")
            .to_return(status: 200, body: mock_issue_with_milestone)
          expect(issue_resource.find_by_number_and_milestone(number, mock_milestone))
            .to eq JSON.parse(mock_issue_with_milestone)
        end
      end
    end
  end

  describe "#create" do
    it "creates the new issue" do
      stub_request(:post, base_request_url)
        .to_return(status: 201, body: mock_issue_with_milestone)
      expect(issue_resource.create(title: "First issue"))
        .to eq JSON.parse(mock_issue_with_milestone)
    end
  end

  describe "#update" do
    it "updates the issue" do
      number = 42
      stub_request(:patch, "#{base_request_url}/#{number}")
        .to_return(status: 200, body: mock_issue_with_milestone)
      expect(issue_resource.update(number, title: "Updated issue"))
        .to eq JSON.parse(mock_issue_with_milestone)
    end
  end
end
