require 'spec_helper'

describe GithubMilestoneResource do
  let(:protocol) { 'https' }
  let(:domain) { 'api.github.com' }
  let(:username) { 'user' }
  let(:password) { 'secret' }
  let(:repo) { 'user/my_repo' }
  let(:base_request_url) do
    "#{protocol}://#{username}:#{password}@#{domain}/repos/#{repo}/milestones"
  end
  let(:service) do
    AhaServices::GithubIssues.new 'server_url' => "#{protocol}://#{domain}",
                                  'username' => username, 'password' => password,
                                  'repository' => repo
  end
  let(:milestone_resource) { GithubMilestoneResource.new(service) }
  let(:mock_milestone) { raw_fixture('github_issues/milestone.json') }

  describe "#find_by_number" do
    let(:number) { 42 }
    context "when a milestone with such number exists" do
      it "returns the milestone" do
        stub_request(:get, "#{base_request_url}/#{number}")
          .to_return(status: 200, body: mock_milestone)
        expect(milestone_resource.find_by_number(number))
          .to eq JSON.parse(mock_milestone)
      end
    end
    context "when there is no milestone with the given number" do
      it "returns nil" do
        stub_request(:get, "#{base_request_url}/#{number}")
          .to_return(status: 404)
        expect(milestone_resource.find_by_number(number))
          .to be_nil
      end
    end
  end

  describe "#find_by_title" do
    before do
      stub_request(:get, base_request_url)
        .to_return(status: 200, body: raw_fixture('github_issues/milestones.json'))
    end
    context "when a milestone with such title exists" do
      it "returns the milestone" do
        title = "First milestone"
        expect(milestone_resource.find_by_title(title)['title'])
          .to eq "First milestone"
      end
    end
    context "when there is no milestone with the given number" do
      title = "Inexistent milestone"
      it "returns nil" do
        expect(milestone_resource.find_by_title(title))
          .to be_nil
      end
    end
  end

  describe "#create" do
    it "creates the new milestone" do
      stub_request(:post, base_request_url)
        .to_return(status: 201, body: mock_milestone)
      expect(milestone_resource.create({ title: "First milestone" }))
        .to eq JSON.parse(mock_milestone)
    end
  end

  describe "#update" do
    it "updates the milestone" do
      number = 42
      stub_request(:patch, "#{base_request_url}/#{number}")
        .to_return(status: 200, body: mock_milestone)
      expect(milestone_resource.update(number, title: "Updated milestone"))
        .to eq JSON.parse(mock_milestone)
    end
  end
end
