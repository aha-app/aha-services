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
  let(:feature) { Hashie::Mash.new name: 'First feature',
                                   description: { body: 'First feature description' },
                                   release: release }

  let(:repo_resource) { double }
  let(:milestone_resource) { double }
  let(:issue_resource) { double }

  before do
    service.stub(:repo_resource).and_return(repo_resource)
    service.stub(:milestone_resource).and_return(milestone_resource)
    service.stub(:issue_resource).and_return(issue_resource)
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

  it "handles the 'create feature' event" do
    mock_payload = Hashie::Mash.new(feature: feature)
    mock_milestone = { number: 1 }
    service.stub(:payload).and_return(mock_payload)
    service.stub(:find_or_attach_github_milestone)
      .and_return(mock_milestone)
    service.stub(:find_or_attach_github_issue)
    service.should_receive(:find_or_attach_github_milestone)
      .with(mock_payload.feature.release)
    service.should_receive(:find_or_attach_github_issue)
      .with(mock_payload.feature, mock_milestone)
    service.receive(:create_feature)
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

  it "handles the 'update feature' event" do
    mock_payload = Hashie::Mash.new(feature: feature)
    mock_milestone = { number: 1 }
    service.stub(:payload).and_return(mock_payload)
    service.stub(:find_or_attach_github_milestone)
      .and_return(mock_milestone)
    service.stub(:update_or_attach_github_issue)
    service.should_receive(:find_or_attach_github_milestone)
      .with(mock_payload.feature.release)
    service.should_receive(:update_or_attach_github_issue)
      .with(mock_payload.feature, mock_milestone)
    service.receive(:update_feature)
  end

  it "handles the 'update release' event" do
    mock_payload = Hashie::Mash.new(release: release)
    service.stub(:payload).and_return(mock_payload)
    service.stub(:update_or_attach_github_milestone)
    service.should_receive(:update_or_attach_github_milestone)
      .with(mock_payload.release)
    service.receive(:update_release)
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

  describe "#update_or_attach_github_milestone" do
    let(:mock_milestone) { { number: 42 } }
    context "when the release is integrated with a github milestone" do
      let(:milestone_number) { 42 }
      before do
        service.stub(:get_integration_field).and_return(milestone_number)
        service.stub(:update_milestone).and_return(mock_milestone)
      end
      it "calls the 'update_milestone' method" do
        service.should_receive(:update_milestone)
          .with(milestone_number, release)
        service.update_or_attach_github_milestone(release)
      end
      it "returns the newly updated milestone" do
        expect(service.update_or_attach_github_milestone(release))
          .to eq mock_milestone
      end
    end

    context "when the release is not integrated with a github milestone" do
      it "attaches a milestone to the release" do
        service.stub(:existing_milestone_integrated_with)
          .and_return(nil)
        service.should_receive(:attach_milestone_to).with(release)
        service.update_or_attach_github_milestone(release)
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

  describe "#update_milestone" do
    it "returns the updated milestone" do
      mock_milestone = { number: 42, title: 'Another milestone' }
      milestone_resource.should_receive(:update).and_return(mock_milestone)
      expect(service.update_milestone(42, release))
        .to eq mock_milestone
    end
  end

  describe "#find_or_attach_github_issue" do
    let(:mock_milestone) { { number: 1 } }
    context "when there is an existing issue integrated with the feature" do
      it "returns the issue" do
        mock_issue = { title: "First issue" }
        service.stub(:existing_issue_integrated_with)
          .and_return(mock_issue)
        expect(service.find_or_attach_github_issue(feature, mock_milestone))
          .to eq mock_issue
      end
    end
    context "when no existing issue is integrated with the feature" do
      it "attaches an issue to the feature" do
        service.stub(:existing_issue_integrated_with)
          .and_return(nil)
        service.should_receive(:attach_issue_to).with(feature, mock_milestone)
        service.find_or_attach_github_issue(feature, mock_milestone)
      end
    end
  end

  describe "#update_or_attach_github_issue" do
    let(:mock_milestone) { { number: 1 } }
    let(:mock_issue) { { number: 42 } }
    context "when the resource is integrated with a github issue" do
      let(:issue_number) { 42 }
      before do
        service.stub(:get_integration_field).and_return(issue_number)
        service.stub(:update_issue).and_return(mock_issue)
      end
      it "calls update_issue method" do
        service.should_receive(:update_issue)
          .with(issue_number, feature)
        service.update_or_attach_github_issue(feature, mock_milestone)
      end
      it "returns the updated issue" do
        expect(service.update_or_attach_github_issue(feature, mock_milestone))
          .to eq mock_issue
      end
    end

    context "when the resource is not integrated with a github issue" do
      it "attaches an issue to the feature" do
        service.stub(:existing_issue_integrated_with)
          .and_return(nil)
        service.should_receive(:attach_issue_to).with(feature, mock_milestone)
        service.update_or_attach_github_issue(feature, mock_milestone)
      end
    end
  end

  describe "#existing_issue_integrated_with" do
    let(:mock_milestone) { { number: 1 } }
    context "when the feature has a 'number' integration field" do
      it "returns the result of 'issue_resource.find_by_number_and_milestone'" do
        issue_number = 42
        mock_issue = { number: issue_number }
        service.stub(:get_integration_field).and_return(issue_number)
        issue_resource.stub(:find_by_number_and_milestone)
          .and_return(mock_issue)
        expect(service.existing_issue_integrated_with(feature, mock_milestone))
          .to eq mock_issue
      end
    end
    context "when the feature doesn't have a 'number' integration field" do
      it "returns nil" do
        service.stub(:get_integration_field).and_return(nil)
        expect(service.existing_issue_integrated_with(feature, mock_milestone))
          .to be_nil
      end
    end
  end

  describe "#attach_issue_to" do
    let(:mock_milestone) { { number: 1 } }
    let(:mock_issue) { { number: 42 } }

    before do
      service.stub(:integrate_resource_with_github_issue)
      service.stub(:create_issue_for).and_return(mock_issue)
    end

    it "creates a new issue" do
      service.should_receive(:create_issue_for).with(feature, mock_milestone)
      service.attach_issue_to(feature, mock_milestone)
    end
    it "integrates the issue with the feature" do
      service.should_receive(:integrate_resource_with_github_issue)
        .with(feature, mock_issue)
      service.attach_issue_to(feature, mock_milestone)
    end
    it "returns the issue" do
      expect(service.attach_issue_to(feature, mock_milestone)).to eq mock_issue
    end
  end

  describe "#create_issue_for" do
    it "returns the newly created issue" do
      mock_issue = { title: 'First issue' }
      mock_milestone = { number: 1 }
      issue_resource.should_receive(:create).and_return(mock_issue)
      expect(service.create_issue_for(feature, mock_milestone)).to eq mock_issue
    end
  end

  describe "#update_issue" do
    it "returns the updated issue" do
      mock_issue = { number: 42, title: 'Another issue' }
      issue_resource.should_receive(:update).and_return(mock_issue)
      expect(service.update_issue(42, feature)).to eq mock_issue
    end
  end
end
