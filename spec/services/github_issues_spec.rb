require 'spec_helper'

describe AhaServices::GithubIssues do
  let(:protocol) { 'https' }
  let(:domain) { 'api.github.com' }
  let(:username) { 'user' }
  let(:password) { 'secret' }
  let(:base_request_url) { "#{protocol}://#{username}:#{password}@#{domain}" }
  let(:service) do
    AhaServices::GithubIssues.new(
      'server_url' => "#{protocol}://#{domain}",
      'username' => username, 'password' => password,
      'repository' => 'user/repo'
    )
  end
  let(:release) { Hashie::Mash.new(name: 'First release') }
  let(:feature) { Hashie::Mash.new(
    name: 'First feature',
    workflow_status: {name: 'In development'},
    description: { body: 'First feature description' },
    release: release,
    tags: [ 'First', 'Second', 'Third', 'Aha!:First' ],
    requirements: [ { id: 'req_id' } ]
  ) }

  let(:repo_resource) { double }
  let(:milestone_resource) { double }
  let(:issue_resource) { double }
  let(:label_resource) { double }
  
  let(:mock_repository) { Hashie::Mash.new(full_name: 'user/repo') }

  before do
    service.stub(:repo_resource).and_return(repo_resource)
    service.stub(:milestone_resource).and_return(milestone_resource)
    service.stub(:issue_resource).and_return(issue_resource)
    service.stub(:label_resource).and_return(label_resource)
  end

  context "can be installed" do
    it "and handles installed event" do
      mock_repos = [ { 'full_name' => 'user/first_repo' } ]
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
    service.stub(:update_requirements)
    service.should_receive(:update_requirements)
      .with(mock_payload.feature.requirements, mock_milestone)
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
    service.stub(:update_requirements)
    service.should_receive(:update_requirements)
      .with(mock_payload.feature.requirements, mock_milestone)
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

  describe "#github_url" do
    it "builds url" do
      expect(service.send(:github_url, ["a"])).to eq("https://api.github.com/user/repo/a")
    end

    it "with params" do
      expect(service.send(:github_url, ["a"], {"b" => "c", "d" => "e"})).to eq("https://api.github.com/user/repo/a?b=c&d=e")
    end

    it "with extra slashes" do
      expect(service.send(:github_url, ["/a","/b/"])).to eq("https://api.github.com/user/repo/a/b")
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
    before { service.stub(:integrate_release_with_github_milestone) }

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

  describe "#update_requirements" do
    shared_examples "empty 'update_requirements' method" do
      it "does not do any api calls" do
        service.update_requirements(requirements, mock_milestone)
      end
    end

    let(:mock_milestone) { { title: 'First milestone' } }
    context "when the requirements are nil" do
      let(:requirements) { nil }
      it_behaves_like "empty 'update_requirements' method"
    end
    context "when the requirements are an empty array" do
      let(:requirements) { [] }
      it_behaves_like "empty 'update_requirements' method"
    end
    context "when the requirements exist" do
      it "calls 'update_or_attach_github_issue' for those requirements" do
        requirements = [ { id: 'first_requirement' }, { id: 'second_requirement' } ]
        service.stub(:update_or_attach_github_issue)
        service.should_receive(:update_or_attach_github_issue).twice
        service.update_requirements(requirements, mock_milestone)
      end
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
          .with(issue_number, feature, mock_milestone)
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
      service.stub(:update_labels)
      issue_resource.should_receive(:create).and_return(mock_issue)
      expect(service.create_issue_for(feature, mock_milestone)).to eq mock_issue
    end
  end

  describe "#update_issue_status" do
    let(:mock_issue) { { number: 42 } }
    before do
      service.stub(:data).and_return(Hashie::Mash.new(status_mapping: {open: '12345', closed: '67890'}))
    end
    context "when the issue state is closed" do
      it "updates the issue state to 'closed'" do
        resource = Hashie::Mash.new({workflow_status: {id: '67890'}})
        issue_resource.should_receive(:update)
          .with(mock_issue["number"], {state: 'closed'})
        service.stub(:issue_resource).and_return(issue_resource)
        service.update_issue_status(mock_issue, resource)
      end
    end
    context "when the there is no matching state" do
      it "does nothing" do
        resource = Hashie::Mash.new({workflow_status: {id: '45678'}})
        issue_resource.should_not_receive(:update)
        service.stub(:issue_resource).and_return(issue_resource)
        service.update_issue_status(mock_issue, resource)
      end
    end

    context "when the issue state is open" do
      it "does nothing" do
        resource = Hashie::Mash.new({workflow_status: {id: '12345'}})
        issue_resource.should_not_receive(:update)
        service.stub(:issue_resource).and_return(issue_resource)
        service.update_issue_status(mock_issue, resource)
      end
    end
  end

  describe "#update_issue" do
    let(:mock_issue) { { number: 42, title: 'Another issue' } }
    let(:mock_milestone) { { number: 1 } }

    it "returns the updated issue" do
      service.stub(:update_labels)
      service.stub(:update_issue_status)
      issue_resource.should_receive(:update).and_return(mock_issue)
      expect(service.update_issue(42, feature, mock_milestone)).to eq mock_issue
    end
  end

  describe "#update_labels" do
    let(:mock_issue) { { number: 42, title: "The issue" } }
    let(:mock_labels) { [{ name: "First label"}] }
    context "add_status_labeled is not enabled" do
      it "returns the updated labels" do
        label_resource.should_receive(:update)
          .with(mock_issue["number"], feature.tags)
          .and_return(mock_labels)
        service.update_labels(mock_issue, feature)
      end
    end
    context "add_status_labeled is enabled" do
      before do
        service.stub(:data).and_return(Hashie::Mash.new({add_status_labels: "1"}))
      end
      it "returns the updated labels" do
        label_resource.should_receive(:update)
          .with(mock_issue["number"], ['First', 'Second', 'Third', 'Aha!:In development'])
          .and_return(mock_labels)
        service.update_labels(mock_issue, feature)
      end
    end
  end

  describe "#issue_body" do
    context "when the description no attachments" do
      context "without body" do
        let(:resource) { Hashie::Mash.new( description: {}) }
        it "returns an empty string" do
          expect(service.issue_body(resource)).to eq ""
        end
      end
      context "with a body" do
        let(:resource) { Hashie::Mash.new( description: { body: "Issue name" }) }
        it "returns the body" do
          expect(service.issue_body(resource)).to eq "Issue name\n\n"
        end
      end

      context "with a url" do
        let(:resource) { Hashie::Mash.new( description: {}, url: "www.example.com") }
        it "returns the body" do
          expect(service.issue_body(resource)).to eq "Created from Aha! www.example.com"
        end
      end


      context "with an underscore inside a code tag in the body" do
        let(:resource) { Hashie::Mash.new( description: { body: "Issue with backticks `method_name*`" }) }
        it "returns the body" do
          expect(service.issue_body(resource)).to eq "Issue with backticks `method_name*`\n\n"
        end
      end

      context "with a github todo in the body" do
        let(:resource) { Hashie::Mash.new( description: { body: "<ul><li>[ ] Todo<br></li></ul>" }) }
        it "returns the body" do
          expect(service.issue_body(resource).delete(' ')).to eq "- [ ] Todo\n\n".delete(' ')
        end
      end
    end
    context "when the description attachments" do
      let(:attachments) { [ { file_name: 'name1', download_url: 'url1' } ] }
      before do
        service.stub(:attachments_in_body).and_return("name1 (url1)")
      end
      context "without body" do
        let(:resource) { Hashie::Mash.new( description: { attachments: attachments }) }
        it "returns the attachments string" do
          expect(service.issue_body(resource)).to eq "name1 (url1)"
        end
      end
      context "with a body" do
        let(:resource) { Hashie::Mash.new( description: { body: "Issue name", attachments: attachments }) }
        it "returns the body followed by the attachments string" do
          expect(service.issue_body(resource))
            .to eq "Issue name\n\n\n\nname1 (url1)"
        end
      end
    end
  end

  describe "#attachments_in_body" do
    context "for zero attachments" do
      let(:attachments) { [] }
      it "returns an empty string" do
        expect(service.attachments_in_body(attachments)).to eq ""
      end
    end
    context "for one attachment" do
      let(:attachments) { [ Hashie::Mash.new(file_name: 'name1', download_url: 'url1') ] }
      it "returns a single string for the attachment" do
        expect(service.attachments_in_body(attachments)).to eq "name1 (url1)"
      end
    end
    context "for two attachments" do
      let(:attachments) { [ Hashie::Mash.new(file_name: 'name1', download_url: 'url1'),
                            Hashie::Mash.new(file_name: 'name2', download_url: 'url2') ] }
      it "returns strings of attachments separated by a newline character" do
        expect(service.attachments_in_body(attachments)).to eq "name1 (url1)\nname2 (url2)"
      end
    end
  end
  #
  describe "#receive_webhook" do
    let(:mock_issue) { { number: 42, title: "The issue", labels: [{name:"First"}, {name:"Second"}, {name: "Third"}, {name: "Aha!:Shipped"}] } }
    let(:mock_api_client) { double }
    after do
      service.stub(:api).and_return(mock_api_client)
      service.receive_webhook
    end
    it "does nothing if more then one integration_field for features is returned" do
        service.stub(:payload).and_return(Hashie::Mash.new({webhook: {action: 'labeled', issue: mock_issue, repository: mock_repository}}))
        mock_api_client.stub(:search_integration_fields).and_return(Hashie::Mash.new({records:[
          {feature:{ resource: 'resource-1', name: 'name-1'}},
          {feature:{ resource: 'resource-2', name: 'name-2'}}
        ]}))
        mock_api_client.should_not_receive(:put)
    end

    it "Updates feature if more than one integration field (feature and release) is returned" do
      service.stub(:payload).and_return(Hashie::Mash.new({webhook: {action: 'labeled', issue: mock_issue, repository: mock_repository}}))
      mock_api_client.stub(:search_integration_fields).and_return(Hashie::Mash.new({records:[
        {feature:{ resource: 'resource-1', name: 'name-1'}},
        {release:{ resource: 'release-2', name: 'name-2'}}
      ]}))
      mock_api_client.should_receive(:put).once()
    end

    it "does nothing if the webhook issue is nil" do
      service.stub(:payload).and_return(Hashie::Mash.new({webhook: {
        action: 'labeled', 
        repository: mock_repository,
      }}))
      mock_api_client.should_not_receive(:search_integration_fields)
    end

    it "does nothing if the webhook action is nil" do
      service.stub(:payload).and_return(Hashie::Mash.new({webhook: {
        issue: mock_issue, 
        repository: mock_repository,
      }}))
      mock_api_client.should_not_receive(:search_integration_fields)
    end

    it "does nothing if the webhook repository is nil" do
      service.stub(:payload).and_return(Hashie::Mash.new({webhook: { 
        action: 'labeled', 
        issue: mock_issue,
      }}))
      mock_api_client.should_not_receive(:search_integration_fields)
    end
    
    it "does nothing if the webhook is configured for a different repository" do
      service.stub(:payload).and_return(Hashie::Mash.new({webhook: { 
        action: 'labeled', 
        issue: mock_issue,
        repository: { full_name: "user/not-our-repo"},
      }}))
      mock_api_client.should_not_receive(:search_integration_fields)
    end
    
    context "with valid results returned from search_integration_fields" do
      let(:valid_search_integration_fields_response) { Hashie::Mash.new({records:[
        {feature:{ resource: 'some-resource', workflow_status:{ name: "In development", id: "12345"}, name: "My Feature", tags: ["First", "Second"]}}
      ]}) }

      before do
        mock_api_client.stub(:search_integration_fields).with(1000, "number", mock_issue[:number]).and_return(valid_search_integration_fields_response)
      end

      context "with add_status_labels enabled" do
        before do
          service.stub(:data).and_return(Hashie::Mash.new(
            add_status_labels: "1", 
            integration_id: 1000, 
            status_mapping: {
              open: {name: 'In development'},
              closed: {name: 'Shipped'},
            },
            repository: "user/repo",
          ))
        end

        context "and labeled action" do
          it "should update the workflow_status" do
            service.stub(:payload).and_return(Hashie::Mash.new({webhook: {action: 'labeled', issue: mock_issue, repository: mock_repository}}))
            expected_diff = {name: "The issue", workflow_status: "Shipped", tags: ["First", "Second", "Third"]}
            mock_api_client.should_receive(:put).with('some-resource', {feature: expected_diff})
          end
          it "should update the issue to only have one aha-label if more then one aha-label is added" do
            mock_issue[:labels].push({name: 'Aha!:In Development'})
            service.stub(:payload).and_return(Hashie::Mash.new({webhook: {action: 'labeled', issue: mock_issue, repository: mock_repository}}))
            label_resource.should_receive(:update).with(mock_issue[:number], ["First", "Second", "Third", "Aha!:In Development"])
            mock_api_client.stub(:put)
          end
        end
        context "and unlabeled action" do
          it "should add the label back to the issue when there is no Aha! labels" do
            mock_issue[:labels].pop # remove the Aha!:In Development label
            service.stub(:payload).and_return(Hashie::Mash.new({label: {name: 'Aha!:Shipped'}, webhook: { action: 'unlabeled', issue: mock_issue, repository: mock_repository }}))
            label_resource.should_receive(:update).with(mock_issue[:number], ["First", "Second", "Third", "Aha!:Shipped"])
            service.stub(:label_resource).and_return(label_resource)
            mock_api_client.stub(:put)
          end
          it "should add the label back to the issue" do
            service.stub(:payload).and_return(Hashie::Mash.new({label: {name: 'Aha!:Shipped'}, webhook: { action: 'unlabeled', issue: mock_issue, repository: mock_repository }}))
            label_resource.should_not_receive(:update)
            service.stub(:label_resource).and_return(label_resource)
            mock_api_client.stub(:put)
          end
        end

        context "and opened action" do
          let(:closed_mock_issue) { { number: 42, title: "The issue", state: "closed", labels: [{name:"First"}, {name:"Second"}, {name: "Third"}, {name: "Aha!:Shipped"}] } }
          let(:opened_mock_issue) { { number: 42, title: "The issue", state: "opened", labels: [{name:"First"}, {name:"Second"}, {name: "Third"}, {name: "Aha!:Shipped"}] } }


          it "should not propagate open labels" do
            service.stub(:payload).and_return(Hashie::Mash.new({label: {name: 'Aha!:Shipped'}, webhook: { action: 'opened', issue: opened_mock_issue, repository: mock_repository }}))
            label_resource.should_not_receive(:update)
            service.stub(:label_resource).and_return(label_resource)
            mock_api_client.stub(:put).and_return(Hashie::Mash.new({feature: {workflow_status: {name: "In development"}}}))
          end

          it "should propagate the open status back to GitHub" do
            service.stub(:payload).and_return(Hashie::Mash.new({label: {name: 'Aha!:Shipped'}, webhook: { action: 'opened', issue: closed_mock_issue, repository: mock_repository }}))
            label_resource.should_receive(:update).with(closed_mock_issue[:number], ["First", "Second", "Third", "Aha!:In development"])
            service.stub(:label_resource).and_return(label_resource)
            mock_api_client.stub(:put).and_return(Hashie::Mash.new({feature: {workflow_status: {name: "In development"}}}))
          end
        end

        context "and closed action" do
          let(:mock_issue) { { number: 42, title: "The issue", state: "closed", labels: [{name:"First"}, {name:"Second"}, {name: "Third"}, {name: "Aha!:Shipped"}] } }

          it "should propagate the closed status back to GitHub" do
            service.stub(:payload).and_return(Hashie::Mash.new({label: {name: 'Aha!:Shipped'}, webhook: { action: 'closed', issue: mock_issue, repository: mock_repository }}))
            label_resource.should_receive(:update).with(mock_issue[:number], ["First", "Second", "Third", "Aha!:Shipped"])
            service.stub(:label_resource).and_return(label_resource)
            mock_api_client.stub(:put).and_return(Hashie::Mash.new({feature: {workflow_status: {name: "Shipped"}}}))
          end
        end
      end
      context "with add_status_labels disabled" do
        before do
          service.stub(:data).and_return(Hashie::Mash.new(
            add_status_labels: "0", 
            integration_id: 1000, 
            status_mapping: {open: '12345', closed: '67890'},
            repository: "user/repo",
          ))
        end

        context "and labeled action" do
          before(:each) do
            service.stub(:payload).and_return(Hashie::Mash.new({webhook: {action: 'labeled', issue: mock_issue, repository: mock_repository}}))
          end
          it "does not change the workflow status" do
            expected_diff = {:name=> "The issue", :tags=>["First", "Second", "Third", "Aha!:Shipped"]}
            mock_api_client.should_receive(:put).with('some-resource', {feature: expected_diff})
          end
        end
        context "and unlabeled action" do
          before(:each) do
            service.stub(:payload).and_return(Hashie::Mash.new({label: {name: 'Shipped'}, webhook: { action: 'unlabeled', issue: mock_issue, repository: mock_repository }}))
          end
          it "does not add the label back to the issue" do
            label_resource.should_not_receive(:update)
            service.stub(:label_resource).and_return(label_resource)
            mock_api_client.stub(:put)
          end
        end
      end
    end
  end
end
