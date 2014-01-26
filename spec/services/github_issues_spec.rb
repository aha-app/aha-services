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
  let(:release) { Hashie::Mash.new(name: 'First release') }

  let(:repo_resource) { double }
  let(:milestone_resource) { double }

  before do
    service.stub(:repo_resource).and_return(repo_resource)
    service.stub(:milestone_resource).and_return(milestone_resource)
  end

  context "can be installed" do
    it "and handles installed event" do
      mock_repos = [ { name: 'First repo' } ]
      repo_resource.stub(:all).and_return(mock_repos)
      service.receive(:installed)
      expect(service.meta_data.repos.first)
        .to eq Hashie::Mash.new(mock_repos.first)
    end
  end

  it "handles the 'create release' event" do
    mock_payload = Hashie::Mash.new(release: release)
    service.stub(:payload).and_return(mock_payload)
    service.stub(:find_or_attach_github_milestone)
      .and_return({ title: "First release" })
    service.should_receive(:find_or_attach_github_milestone)
      .with(mock_payload.release)
    service.receive(:create_release)
  end

  describe "#find_or_attach_github_milestone" do
    context "when there is an existing milestone integrated with the release" do
      it "returns the milestone" do
        mock_milestone = { title: 'First milestone' }
        service.stub(:existing_milestone_integrated_with)
          .and_return(mock_milestone)
        expect(service.find_or_attach_github_milestone(release))
          .to eq mock_milestone
      end
    end
    context "when no existing milestone is integrated with the release" do
      it "attaches a milestone to the release" do
        service.stub(:existing_milestone_integrated_with)
          .and_return(nil)
        service.should_receive(:attach_milestone_to).with(release)
        service.find_or_attach_github_milestone(release)
      end
    end
  end

  describe "#existing_milestone_integrated_with" do
    context "when the release has a 'number' integration field" do
      it "returns the result of 'milestone_resource.find_by_number'" do
        milestone_number = 42
        mock_milestone = { number: 42, title: 'First milestone' }
        service.stub(:get_integration_field).and_return(milestone_number)
        milestone_resource.stub(:find_by_number)
          .and_return(mock_milestone)
        expect(service.existing_milestone_integrated_with(release))
          .to eq mock_milestone
      end
    end
    context "when the release doesn't have a 'number' integration field" do
      it "returns nil" do
        service.stub(:get_integration_field).and_return(nil)
        expect(service.existing_milestone_integrated_with(release))
          .to be_nil
      end
    end
  end

  describe "#attach_milestone_to" do
    let(:mock_milestone) { { 'number' => 42 } }
    before { service.api.stub(:create_integration_field) }

    shared_examples "attaching the milestone" do
      it "integrates the milestone with the release" do
        service.should_receive(:integrate_release_with_github_milestone)
          .with(release, mock_milestone)
        service.attach_milestone_to(release)
      end
      it "returns the milestone" do
        expect(service.attach_milestone_to(release)).to eq mock_milestone
      end
    end

    context "when a milestone with a title the same as release's name exists" do
      before do
        milestone_resource.stub(:find_by_title).and_return(mock_milestone)
      end

      it_behaves_like "attaching the milestone"
    end
    context "when a milestone with a corresponding title doesn't exist" do
      before do
        milestone_resource.stub(:find_by_title).and_return(nil)
        service.stub(:create_milestone_for).and_return(mock_milestone)
      end
      it "creates a new milestone" do
        service.should_receive(:create_milestone_for).with(release)
        service.attach_milestone_to(release)
      end

      it_behaves_like "attaching the milestone"
    end
  end

  describe "#create_milestone_for" do
    let(:mock_milestone) { { title: 'First milestone' } }
    before do
      milestone_resource.should_receive(:create).and_return(mock_milestone)
    end
    it "returns the newly created milestone" do
      expect(service.create_milestone_for(release)).to eq mock_milestone
    end
  end
end

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
      stub_request(:get, "#{base_request_url}/user/repos").
        to_return(status: 200, body: mock_repos)
      expect(repo_resource.all).to eq JSON.parse(mock_repos)
    end
  end
end

describe GithubMilestoneResource do
  let(:protocol) { 'https' }
  let(:domain) { 'api.github.com' }
  let(:username) { 'user' }
  let(:password) { 'secret' }
  let(:repo) { 'my_repo' }
  let(:base_request_url) do
    "#{protocol}://#{username}:#{password}@#{domain}/repos/#{username}/#{repo}/milestones"
  end
  let(:service) do
    AhaServices::GithubIssues.new 'server_url' => "#{protocol}://#{domain}",
                                  'username' => username, 'password' => password,
                                  'repo' => repo
  end
  let(:milestone_resource) { GithubMilestoneResource.new(service) }
  let(:mock_milestone) { raw_fixture('github_issues/milestone.json') }

  describe "#find_by_number" do
    let(:number) { 42 }
    context "when a milestone with such number exists" do
      before do
        stub_request(:get, "#{base_request_url}/#{number}")
          .to_return(status: 200, body: mock_milestone)
      end
      it "returns the milestone" do
        expect(milestone_resource.find_by_number(number))
          .to eq JSON.parse(mock_milestone)
      end
    end
    context "when there is no milestone with the given number" do
      before do
        stub_request(:get, "#{base_request_url}/#{number}")
          .to_return(status: 404)
      end
      it "returns nil" do
        expect(milestone_resource.find_by_number(number))
          .to be_nil
      end
    end
  end
end
