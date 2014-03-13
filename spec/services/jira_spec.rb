require 'spec_helper'

describe AhaServices::Jira do
  let(:integration_data) { {'projects'=>[{'id'=>'10000', 'key'=>'DEMO', 'name'=>'Aha! App Development', 'issue_types'=>[{'id'=>'1', 'name'=>'Bug', 'subtask'=>false, 'statuses'=>[{'id'=>'1', 'name'=>'Open'}, {'id'=>'3', 'name'=>'In Progress'}, {'id'=>'5', 'name'=>'Resolved'}, {'id'=>'4', 'name'=>'Reopened'}, {'id'=>'6', 'name'=>'Closed'}]}, {'id'=>'2', 'name'=>'New Feature', 'subtask'=>false, 'statuses'=>[{'id'=>'1', 'name'=>'Open'}, {'id'=>'3', 'name'=>'In Progress'}, {'id'=>'5', 'name'=>'Resolved'}, {'id'=>'4', 'name'=>'Reopened'}, {'id'=>'6', 'name'=>'Closed'}]}, {'id'=>'3', 'name'=>'Task', 'subtask'=>false, 'statuses'=>[{'id'=>'1', 'name'=>'Open'}, {'id'=>'3', 'name'=>'In Progress'}, {'id'=>'5', 'name'=>'Resolved'}, {'id'=>'4', 'name'=>'Reopened'}, {'id'=>'6', 'name'=>'Closed'}]}, {'id'=>'4', 'name'=>'Improvement', 'subtask'=>false, 'statuses'=>[{'id'=>'1', 'name'=>'Open'}, {'id'=>'3', 'name'=>'In Progress'}, {'id'=>'5', 'name'=>'Resolved'}, {'id'=>'4', 'name'=>'Reopened'}, {'id'=>'6', 'name'=>'Closed'}]}, {'id'=>'5', 'name'=>'Sub-task', 'subtask'=>true, 'statuses'=>[{'id'=>'1', 'name'=>'Open'}, {'id'=>'3', 'name'=>'In Progress'}, {'id'=>'5', 'name'=>'Resolved'}, {'id'=>'4', 'name'=>'Reopened'}, {'id'=>'6', 'name'=>'Closed'}]}, {'id'=>'6', 'name'=>'Epic', 'subtask'=>false, 'statuses'=>[{'id'=>'1', 'name'=>'Open'}, {'id'=>'3', 'name'=>'In Progress'}, {'id'=>'5', 'name'=>'Resolved'}, {'id'=>'4', 'name'=>'Reopened'}, {'id'=>'6', 'name'=>'Closed'}]}, {'id'=>'7', 'name'=>'Story', 'subtask'=>false, 'statuses'=>[{'id'=>'1', 'name'=>'Open'}, {'id'=>'3', 'name'=>'In Progress'}, {'id'=>'5', 'name'=>'Resolved'}, {'id'=>'4', 'name'=>'Reopened'}, {'id'=>'6', 'name'=>'Closed'}]}, {'id'=>'8', 'name'=>'Technical task', 'subtask'=>true, 'statuses'=>[{'id'=>'1', 'name'=>'Open'}, {'id'=>'3', 'name'=>'In Progress'}, {'id'=>'5', 'name'=>'Resolved'}, {'id'=>'4', 'name'=>'Reopened'}, {'id'=>'6', 'name'=>'Closed'}]}]}]} }

  let(:protocol) { 'http' }
  let(:server_url) { 'foo.com/a' }
  let(:api_url) { 'rest/api/2' }
  let(:username) { 'u' }
  let(:password) { 'p' }
  let(:base_url) { "#{protocol}://#{username}:#{password}@#{server_url}/#{api_url}" }
  let(:service_params) do
    {
      'server_url' => "#{protocol}://#{server_url}",
      'username' => username, 'password' => password,
      'project' => 'DEMO', 'feature_issue_type' => '6'
    }
  end
  let(:service) do
    AhaServices::Jira.new service_params
  end

  def stub_creating_version
    # Verify release.
    stub_request(:get, "#{base_url}/version/777").
      to_return(:status => 200, :body => "", :headers => {})
    # Create version.
    stub_request(:get, "#{base_url}/project/DEMO/versions").
      to_return(:status => 200, :body => "[]", :headers => {})
    stub_request(:post, "#{base_url}/version").
      with(:body => "{\"name\":\"Summer\",\"description\":\"Created from Aha! \",\"releaseDate\":null,\"released\":null,\"project\":\"DEMO\"}").
      to_return(:status => 201, :body => "{\"id\":\"666\"}", :headers => {})
    # Call back into Aha! for release.
    stub_request(:post, "https://a.aha.io/api/v1/releases/PROD-R-1/integrations/jira/fields").
      with(:body => {:integration_field => {:name => "id", :value => "666"}}).
      to_return(:status => 201, :body => "", :headers => {})
  end
  
  it "can receive new features" do
    stub_creating_version
    
    # Verify release.
    stub_request(:get, "#{base_url}/version/777").
      to_return(:status => 200, :body => "", :headers => {})
    # Call to Jira
    stub_request(:post, "#{base_url}/issue").
      to_return(:status => 201, :body => "{\"id\":\"10009\",\"key\":\"DEMO-10\",\"self\":\"https://myhost.atlassian.net/rest/api/2/issue/10009\"}", :headers => {})
    # Add attachments.
    stub_request(:post, "#{base_url}/issue/10009/attachments").
      to_return(:status => 200)
    # Link to requirement.
    stub_request(:post, "#{base_url}/issueLink").
      with(:body => "{\"type\":{\"name\":\"Relates\"},\"outwardIssue\":{\"id\":\"10009\"},\"inwardIssue\":{\"id\":\"10009\"}}").
      to_return(:status => 201)

    # Call back into Aha! for feature
    stub_request(:post, "https://a.aha.io/api/v1/features/5886067808745625353/integrations/jira/fields").
      with(:body => {:integration_field => {:name => "id", :value => "10009"}}).
      to_return(:status => 201, :body => "", :headers => {})
    stub_request(:post, "https://a.aha.io/api/v1/features/5886067808745625353/integrations/jira/fields").
      with(:body => {:integration_field => {:name => "key", :value => "DEMO-10"}}).
      to_return(:status => 201, :body => "", :headers => {})
    stub_request(:post, "https://a.aha.io/api/v1/features/5886067808745625353/integrations/jira/fields").
      with(:body => {:integration_field => {:name => "url", :value => "http://foo.com/a/browse/DEMO-10"}}).
      to_return(:status => 201, :body => "", :headers => {})
    # Call back into Aha! for requirement
    stub_request(:post, "https://a.aha.io/api/v1/requirements/5886072825272941795/integrations/jira/fields").
      with(:body => {:integration_field => {:name => "id", :value => "10009"}}).
      to_return(:status => 201, :body => "", :headers => {})
    stub_request(:post, "https://a.aha.io/api/v1/requirements/5886072825272941795/integrations/jira/fields").
      with(:body => {:integration_field => {:name => "key", :value => "DEMO-10"}}).
      to_return(:status => 201, :body => "", :headers => {})
    stub_request(:post, "https://a.aha.io/api/v1/requirements/5886072825272941795/integrations/jira/fields").
      with(:body => {:integration_field => {:name => "url", :value => "http://foo.com/a/browse/DEMO-10"}}).
      to_return(:status => 201, :body => "", :headers => {})
    
    stub_download_feature_attachments
        
    AhaServices::Jira.new(service_params,
                          json_fixture('create_feature_event.json'),
                          integration_data)
      .receive(:create_feature)
  end
  
  it "can update existing features" do
    # Verify release.
    stub_request(:get, "#{base_url}/version/777").
      to_return(:status => 200, :body => "", :headers => {})
    
    # Call to Jira
    stub_request(:get, "#{base_url}/issue/10009?fields=attachment").
      to_return(:status => 200, :body => raw_fixture('jira/jira_attachments.json'), :headers => {})
    stub_request(:put, "#{base_url}/issue/10009").
      to_return(:status => 204, :body => "{\"fields\":{\"description\":\"\\n\\nCreated from Aha! [PROD-2|http://watersco.aha.io/features/PROD-2]\",\"summary\":\"Feature with attachments\"}}", :headers => {})
    
    stub_download_feature_attachments
      
    # Upload new attachments.
    stub_request(:post, "#{base_url}/issue/10009/attachments").
      with(:body => "-------------RubyMultipartPost\r\nContent-Disposition: form-data; name=\"file\"; filename=\"Belgium.png\"\r\nContent-Length: 6\r\nContent-Type: image/png\r\nContent-Transfer-Encoding: binary\r\n\r\nbbbbbb\r\n-------------RubyMultipartPost--\r\n\r\n").
      to_return(:status => 200, :body => "", :headers => {})
    stub_request(:post, "#{base_url}/issue/10009/attachments").
      with(:body => "-------------RubyMultipartPost\r\nContent-Disposition: form-data; name=\"file\"; filename=\"France.png\"\r\nContent-Length: 6\r\nContent-Type: image/png\r\nContent-Transfer-Encoding: binary\r\n\r\ndddddd\r\n-------------RubyMultipartPost--\r\n\r\n").
      to_return(:status => 200, :body => "", :headers => {})
  
  
    AhaServices::Jira.new(service_params,
                          json_fixture('update_feature_event.json'),
                          integration_data)
      .receive(:update_feature)
  end
  
  it "raises error when Jira fails" do
    stub_creating_version
    
    stub_request(:post, "#{base_url}/issue").
      to_return(:status => 400, :body => "{\"errorMessages\":[],\"errors\":{\"description\":\"Operation value must be a string\"}}", :headers => {})
    expect do
      AhaServices::Jira.new(service_params,
                            json_fixture('create_feature_event.json'),
                            integration_data)
        .receive(:create_feature)
    end.to raise_error(AhaService::RemoteError)
  end
  
  it "raises authentication error" do
    stub_creating_version
    
    stub_request(:post, "#{base_url}/issue").
      to_return(:status => 401, :body => "", :headers => {})
    expect do
      AhaServices::Jira.new(service_params,
                            json_fixture('create_feature_event.json'),
                            integration_data)
        .receive(:create_feature)
    end.to raise_error(AhaService::RemoteError)
  end
  
  context "releases" do
    it "can be updated" do
      stub_request(:put, "#{base_url}/version/777").
        with(:body => "{\"name\":\"Production Web Hosting\",\"releaseDate\":\"2013-01-28\",\"released\":false,\"id\":\"777\"}").
        to_return(:status => 200, :body => "", :headers => {})
      
      AhaServices::Jira.new(service_params,
                            json_fixture('update_release_event.json'))
        .receive(:update_release)
    end
    
    it "can handle version being deleted" do
    end
    
  end
  
  context "can be installed" do
    
    it "handles installed event" do
      stub_request(:get, "#{base_url}/issue/createmeta?expand=projects.issuetypes.fields").
        to_return(:status => 200, :body => raw_fixture('jira/jira_createmeta.json'), :headers => {})
      stub_request(:get, "#{base_url}/project/APPJ/statuses").
        to_return(:status => 200, :body => raw_fixture('jira/jira_project_statuses.json'), :headers => {})
      stub_request(:get, "#{base_url}/resolution").
        to_return(:status => 200, :body => raw_fixture('jira/jira_resolutions.json'), :headers => {})
      stub_request(:get, "#{base_url}/field").
        to_return(:status => 200, :body => raw_fixture('jira/jira_field.json'), :headers => {})
      
      service = AhaServices::Jira.new(service_params)
      service.receive(:installed)
      service.meta_data.projects[0]["key"].should == "APPJ"
      service.meta_data.projects[0].issue_types[0].name.should == "Bug"     
      service.meta_data.projects[0].issue_types[0].statuses[0].name.should == "Open"     
    end
    
    it "handles installed event for Jira 5.0" do
      stub_request(:get, "#{base_url}/issue/createmeta?expand=projects.issuetypes.fields").
        to_return(:status => 200, :body => raw_fixture('jira/jira_createmeta.json'), :headers => {})
      stub_request(:get, "#{base_url}/project/APPJ/statuses").
        to_return(:status => 404, :headers => {})
      stub_request(:get, "#{base_url}/status").
        to_return(:status => 200, :body => raw_fixture('jira/jira_status.json'), :headers => {})
      stub_request(:get, "#{base_url}/resolution").
        to_return(:status => 200, :body => raw_fixture('jira/jira_resolutions.json'), :headers => {})
      stub_request(:get, "#{base_url}/field").
        to_return(:status => 200, :body => raw_fixture('jira/jira_field.json'), :headers => {})
    
      service = AhaServices::Jira.new(service_params)
      service.receive(:installed)
      service.meta_data.projects[0]["key"].should == "APPJ"
      service.meta_data.projects[0].issue_types[0].name.should == "Bug"     
      service.meta_data.projects[0].issue_types[0].statuses[0].name.should == "Open"     
    end
    
  end

  before do
    service.stub(:issue_resource).and_return(double)
    service.stub(:field_resource).and_return(double)
    service.stub(:version_resource).and_return(double)
    service.stub(:issue_link_resource).and_return(double)
    service.stub(:attachment_resource).and_return(double)
  end

  let(:issue_resource) { service.send(:issue_resource) }
  let(:field_resource) { service.send(:field_resource) }
  let(:version_resource) { service.send(:version_resource) }
  let(:issue_link_resource) { service.send(:issue_link_resource) }
  let(:attachment_resource) { service.send(:attachment_resource) }

  describe "#new_or_existing_aha_reference_field" do
    context "when a reference field exists" do
      it "returns the existing field" do
        field_resource.stub(:aha_reference_field)
          .and_return('ref_field')
        expect(service.send(:new_or_existing_aha_reference_field))
          .to eq 'ref_field'
      end
    end

    context "when a reference field doesn't exist" do
      let(:new_field) { 'new_ref_field' }
      before do
        field_resource.stub(:aha_reference_field)
          .and_return(nil)
        field_resource.stub(:create).and_return(new_field)
        field_resource.stub(:add_to_default_screen)
      end
      it "creates a new field and returns it" do
        field_resource.should_receive(:create)
        expect(service.send(:new_or_existing_aha_reference_field))
          .to eq new_field
      end

      it "it adds the field to the default screen" do
        field_resource.should_receive(:add_to_default_screen)
        service.send(:new_or_existing_aha_reference_field)
      end
    end
  end

  describe "#find_or_attach_jira_version" do
    let(:release) { { name: 'First release' } }
    context "when an existing version is integrated" do
      let(:version) { { name: 'Existing version' } }
      it "returns this version" do
        service.stub(:existing_version_integrated_with)
          .and_return(version)
        expect(service.send(:find_or_attach_jira_version, release))
          .to eq version
      end
    end

    context "when a version is not integrated or doesn't exist" do
      let(:version) { { name: 'Newly attached version' } }
      it "calls attach_version_to with release and returns its result" do
        service.stub(:existing_version_integrated_with)
          .and_return(nil)
        service.should_receive(:attach_version_to).with(release)
          .and_return(version)
        expect(service.send(:find_or_attach_jira_version, release))
          .to eq version
      end
    end
  end

  describe "#update_or_attach_jira_version" do
    let(:release) { Hashie::Mash.new(name: 'First release') }
    let(:version_id) { 1001 }
    context "when a version is integrated" do
      it "updates the version" do
        service.stub(:get_integration_field).and_return(version_id)
        service.should_receive(:update_version)
          .with(version_id, release)
        service.send(:update_or_attach_jira_version, release)
      end
    end

    context "when a version is not integrated" do
      it "attaches a version to the release" do
        service.stub(:get_integration_field).and_return(nil)
        service.should_receive(:attach_version_to).with(release)
        service.send(:update_or_attach_jira_version, release)
      end
    end
  end

  describe "#existing_version_integrated_with" do
    let(:release) { Hashie::Mash.new(name: 'First release') }
    let(:version_id) { 1001 }
    context "when a version is integrated" do
      it "searches the version by id and returns it" do
        found_version = { name: 'Existing version' }
        service.stub(:get_integration_field).and_return(version_id)
        version_resource.should_receive(:find_by_id).with(version_id)
          .and_return(found_version)
        expect(service.send(:existing_version_integrated_with, release))
          .to eq found_version
      end
    end

    context "when a version is not integrated" do
      it "does nothing" do
        service.stub(:get_integration_field).and_return(nil)
        expect(service.send(:existing_version_integrated_with, release))
          .to be_nil
      end
    end
  end

  describe "#attach_version_to" do
    let(:version) { { name: 'Some version' } }
    let(:release) { Hashie::Mash.new(name: 'Some release') }
    before do
      service.stub(:integrate_release_with_jira_version)
    end
    shared_examples "after searching for existing version" do
      it "integrates the release with the version and returns it" do
        service.should_receive(:integrate_release_with_jira_version)
          .with(release, version)
        expect(service.send(:attach_version_to, release))
          .to eq version
      end
    end
    context "when a version with the same name exists in Jira" do
      before do
        version_resource.stub(:find_by_name).and_return(version)
      end

      it_behaves_like "after searching for existing version"
    end

    context "when there is no version with such name in Jira" do
      before do
        version_resource.stub(:find_by_name).and_return(nil)
        service.stub(:create_version_for).and_return(version)
      end
      it "creates a new version for the release" do
        service.should_receive(:create_version_for)
        service.send(:attach_version_to, release)
      end

      it_behaves_like "after searching for existing version"
    end
  end

  describe "#update_requirements" do
    before do
      service.stub(:update_or_attach_jira_issue)
    end
    context "when the feature has requirements" do
      let(:feature) { Hashie::Mash.new(name: 'Feature',
                        requirements: [:req1, :req2, :req3]) }
      it "calls update_or_attach_jira_issue for each requirement" do
        service.should_receive(:update_or_attach_jira_issue)
          .exactly(3).times
        service.send(:update_requirements, feature, nil, nil)
      end
    end

    context "when the feature doesn't have requirements" do
      let(:feature) { Hashie::Mash.new(name: 'Feature') }
      it "does nothing" do
        service.should_not_receive(:update_or_attach_jira_issue)
        service.send(:update_requirements, feature, nil, nil)
      end
    end
  end

  describe "#get_existing_issue_info" do
    let(:resource) { Hashie::Mash.new(name: 'My resource') }
    let(:result) { service.send(:get_existing_issue_info, resource) }
    context "when the resource has the needed integration fields" do
      it "returns a new hashie" do
        service.stub(:get_integration_field).with(nil, 'id').and_return('id')
        service.stub(:get_integration_field).with(nil, 'key').and_return('key')
        expect(result).to eq Hashie::Mash.new(id: 'id', key: 'key')
      end
    end

    context "when the resource doesn't have an 'id' integration field" do
      it "returns nil" do
        service.stub(:get_integration_field).with(nil, 'id').and_return(nil)
        service.stub(:get_integration_field).with(nil, 'key').and_return('key')
        expect(result).to be_nil
      end
    end

    context "when the resource doesn't have a 'key' integration field" do
      it "returns nil" do
        service.stub(:get_integration_field).with(nil, 'id').and_return('id')
        service.stub(:get_integration_field).with(nil, 'key').and_return(nil)
        expect(result).to be_nil
      end
    end
  end

  describe "#update_or_attach_jira_issue" do
    context "when issue info exists" do
      it "calls update_issue" do
        service.stub(:get_existing_issue_info)
          .and_return(:existing_issue)
        service.should_receive(:update_issue)
        service.send(:update_or_attach_jira_issue, nil, nil, nil)
      end
    end

    context "when issue info doesn't exist" do
      it "calls attach_issue_to" do
        service.stub(:get_existing_issue_info)
          .and_return(nil)
        service.should_receive(:attach_issue_to)
        service.send(:update_or_attach_jira_issue, nil, nil, nil)
      end
    end
  end

  describe "#attach_issue_to" do
    it "executes a sequence of methods and return the new issue" do
      resource = Hashie::Mash.new(description: {})
      new_issue = Hashie::Mash.new(id: 1001)
      service.should_receive(:create_issue_for).and_return(new_issue)
      service.should_receive(:integrate_resource_with_jira_issue)
      service.should_receive(:upload_attachments).twice
      expect(service.send(:attach_issue_to, resource, nil, nil))
        .to eq new_issue
    end
  end

  describe "#epic_key_for_initiative" do
    let(:initiative) { Hashie::Mash.new }
    let(:result) { service.send(:epic_key_for_initiative, initiative) }
    context "when an integration exists for the initiative" do
      it "returns the integrated issue's key" do
        service.stub(:get_integration_field).and_return('some_key')
        expect(result).to eq 'some_key'
      end
    end

    context "when an integration doesn't exist for the initiative" do
      before { service.stub(:get_integration_field).and_return(nil) }
      context "when an issue type exists for epics" do
        it "creates a new issue and returns its key" do
          service.stub(:epic_issue_type).and_return('Epic')
          created_issue = Hashie::Mash.new(key: 'new_key')
          service.should_receive(:create_issue_for_initiative)
            .and_return(created_issue)
          expect(result).to eq 'new_key'
        end
      end

      context "when there's no issue type for epics" do
        it "returns nil" do
          service.stub(:epic_issue_type).and_return(nil)
          expect(result).to be_nil
        end
      end
    end
  end

  describe "#create_issue_for_initiative" do
    let(:initiative) do
      Hashie::Mash.new(name: 'Initiative name',
                       description: { body: 'Initiative body' })
    end
    let(:issue_type) { Hashie::Mash.new(id: 42) }
    let(:new_issue) { Hashie::Mash.new(id: 1001) }
    it "performs certain operations and returns the new issue" do
      issue_resource.should_receive(:create).and_return(new_issue)
      service.should_receive(:upload_attachments)
      service.should_receive(:integrate_initiative_with_jira_issue)
      expect(service.send(:create_issue_for_initiative, initiative, issue_type))
        .to eq new_issue
    end
  end

  describe "#create_issue_for" do
    let(:resource) do
      Hashie::Mash.new(name: 'Resource name',
                       description: { body: 'Resource body' })
    end

    it "calls issue_resource.create and create_link_for_issue,\
        and then returns the newly created issue" do
      service.stub(:issue_type_by_parent)
        .and_return(Hashie::Mash.new(name: 'Story', subtask: false))
      issue_resource.should_receive(:create).and_return({key: 'New issue', id: 1})
      service.should_receive(:create_link_for_issue).and_return(nil)
      expect(service.send(:create_issue_for, resource, nil, nil, nil))
        .to eq({key: 'New issue', id: 1})
    end
  end

  describe "#update_issue" do
    let(:issue_info) do
      Hashie::Mash.new(id: '1001')
    end
    let(:resource) do
      Hashie::Mash.new(name: 'Resource name',
                       description: { body: 'Resource body' })
    end

    it "calls issue_resource.update and update_attachments,\
        and then returns the issue_info object" do
      service.stub(:issue_type_by_parent)
        .and_return(Hashie::Mash.new(name: 'Story', subtask: false))
      issue_resource.should_receive(:update)
      service.should_receive(:update_attachments).and_return(nil)
      expect(service.send(:update_issue, issue_info, resource, nil, nil, nil))
        .to eq issue_info
    end
  end

  describe "#create_link_for_issue" do
    shared_examples "empty create_link_for_issue method" do
      it "does not call issue_link_resource.create" do
        issue_link_resource.should_not_receive(:create)
        result
      end
    end

    let(:issue) { Hashie::Mash.new }
    let(:result) do
      service.send(:create_link_for_issue, issue, issue_type, parent)
    end
    context "when the issue has a parent" do
      let(:parent) { Hashie::Mash.new }
      context "when the issue is a subtask" do
        let(:issue_type) { Hashie::Mash.new(subtask: true, name: 'Issue') }
        it_behaves_like "empty create_link_for_issue method"
      end

      context "when the issue is not a subtask" do
        let(:is_subtask) { false }
        context "when the issue type has an epic link field" do
          let(:issue_type) { Hashie::Mash.new(subtask: is_subtask, has_field_epic_link: true) }
          it_behaves_like "empty create_link_for_issue method"
        end

        context "when the issue type has an epic name field" do
          let(:issue_type) { Hashie::Mash.new(subtask: is_subtask, has_field_epic_name: true) }
          it_behaves_like "empty create_link_for_issue method"
        end

        context "when the issue is neither an Epic nor a Story" do
          let(:issue_type) { Hashie::Mash.new(subtask: is_subtask) }
          it "calls issue_link_resource.create" do
            issue_link_resource.should_receive(:create)
            result
          end
        end
      end
    end

    context "when the issue doesn't have a parent" do
      let(:parent) { nil }
      let(:issue_type) { Hashie::Mash.new(subtask: false, name: 'Issue')}
      it_behaves_like "empty create_link_for_issue method"
    end
  end

  describe "#update_attachments" do
    it "uploads new attachments from the combined resource.attachments\
        and resource.description.attachments array" do
      issue_id = 1001
      resource = Hashie::Mash.new(attachments: [1, 2, 3],
                                  description: { attachments: [3, 4] })
      service.should_receive(:new_aha_attachments).with([1, 2, 3, 4], issue_id)
      service.should_receive(:upload_attachments)
      service.send(:update_attachments, issue_id, resource)
    end
  end

  describe "#new_aha_attachments" do
    let(:issue_id) { 1001 }
    let(:result) { service.send(:new_aha_attachments, aha_attachments, issue_id) }
    before do
      service.stub(:attachments_match) { |arg1, arg2| arg1 == arg2 }
    end
    context "when all attachments match" do
      let(:aha_attachments) { [1, 2, 3] }
      it "returns an empty array" do
        attachment_resource.stub(:all_for_issue).and_return([1, 2, 3])
        expect(result).to eq []
      end
    end

    context "when there are new attachments in Jira" do
      let(:aha_attachments) { [1, 2, 3]}
      it "returns an empty array" do
        attachment_resource.stub(:all_for_issue).and_return([1, 2, 3, 4, 5])
        expect(result).to eq []
      end
    end

    context "when there are new attachments in Aha" do
      let(:aha_attachments) { [1, 2, 3, 4, 5] }
      it "returns the array with new attachments" do
        attachment_resource.stub(:all_for_issue).and_return([1, 2, 3])
        expect(result).to eq [4, 5]
      end
    end
  end

  describe "#version_fields" do
    let(:version_fields) { service.send(:version_fields, version, issue_type) }
    context "when a version exists" do
      let(:version) { Hashie::Mash.new(id: '1001') }
      context "when issue type has fix versions field" do
        let(:issue_type) { Hashie::Mash.new(has_field_fix_versions: true) }
        it "returns a specific hash" do
          expect(version_fields).to eq(fixVersions: [{ id: version.id }])
        end
      end

      context "when issue type doesn't have fix versions field" do
        let(:issue_type) { Hashie::Mash.new }
        it "returns an empty hash" do
          expect(version_fields).to eq Hash.new
        end
      end
    end

    context "when there is no version" do
      let(:version) { nil }
      let(:issue_type) { Hashie::Mash.new(has_field_fix_versions: true) }
      it "returns an empty hash" do
        expect(version_fields).to eq Hash.new
      end
    end
  end

  describe "#label_fields" do
    let(:label_fields) { service.send(:label_fields, resource, issue_type) }
    shared_examples "empty label fields" do
      it "returns an empty hash" do
        expect(label_fields)
          .to eq Hash.new
      end
    end

    context "when the resource has tags" do
      let(:resource) { Hashie::Mash.new(tags: [ {tag1: 'Tag name'} ]) }
      context "when tags are set to be synchronized" do
        before do
          service.stub(:data).and_return(Hashie::Mash.new(send_tags: "1"))
        end
        context "when issue type has labels field" do
          let(:issue_type) { Hashie::Mash.new(has_field_labels: true) }
          it "returns a specific hash" do
            expect(label_fields)
              .to eq(labels: resource.tags)
          end
        end

        context "when issue type doesn't have labels field" do
          let(:issue_type) { Hashie::Mash.new }
          it_behaves_like "empty label fields"
        end
      end

      context "when tags are not set to be synchronized" do
        let(:issue_type) { Hashie::Mash.new(has_field_labels: true) }
        before { service.stub(:data).and_return(Hashie::Mash.new) }
        it_behaves_like "empty label fields"
      end
    end

    context "when the resource doesn't have tags" do
      let(:issue_type) { Hashie::Mash.new(has_field_labels: true) }
      let(:resource) { Hashie::Mash.new }
      it_behaves_like "empty label fields"
    end
  end

  describe "#aha_reference_fields" do
    let(:aha_reference_fields) do
      service.send(:aha_reference_fields, resource, issue_type)
    end
    let(:resource) { Hashie::Mash.new(url: 'http://example.com') }
    context "when issue type has aha reference field" do
      let(:issue_type) { Hashie::Mash.new(has_field_aha_reference: true) }
      it "returns a specific hash" do
        service.stub(:meta_data)
          .and_return(Hashie::Mash.new(aha_reference_field: 'ref'))
        expect(aha_reference_fields)
          .to eq('ref' => resource.url)
      end
    end

    context "when issue type doesn't have aha reference field" do
      let(:issue_type) { Hashie::Mash.new }
      it "returns an empty hash" do
        expect(aha_reference_fields)
          .to eq Hash.new
      end
    end
  end

  describe "#time_tracking_fields" do
    let(:time_tracking_fields) do
      service.send(:time_tracking_fields, resource, issue_type)
    end
    context "when units are minutes" do
      let(:resource) do
        Hashie::Mash.new({ work_units: 10,
                           original_estimate: 20,
                           remaining_estimate: 30 })
      end
      context "when issue type has time tracking field" do
        let(:issue_type) { Hashie::Mash.new(has_field_time_tracking: true) }
        it "returns a hash with a timetracking field" do
          expect(time_tracking_fields).to eq(
            {
              timetracking: {
                originalEstimate: resource.original_estimate,
                remainingEstimate: resource.remaining_estimate
              }
            }
          )
        end
      end
      context "when issue type doesn't have a time tracking field" do
        let(:issue_type) { Hashie::Mash.new }
        it "returns an empty hash" do
          expect(time_tracking_fields).to eq Hash.new
        end
      end
    end

    context "when units are points" do
      let(:resource) do
        Hashie::Mash.new({ work_units: 20,
                           remaining_estimate: 100 })
      end
      context "when issue type has a story points field" do
        let(:issue_type) { Hashie::Mash.new(has_field_story_points: true) }
        it "returns a hash with the field meta_data.story_points_field" do
          service.stub(:meta_data)
            .and_return(Hashie::Mash.new({ story_points_field: 'story_points' }))
          expect(time_tracking_fields).to eq(
            service.meta_data.story_points_field => resource.remaining_estimate
          )
        end
      end

      context "when issue type doesn't have a story points field" do
        let(:issue_type) { Hashie::Mash.new }
        it "returns an empty hash" do
          expect(time_tracking_fields).to eq Hash.new
        end
      end
    end

    context "when units are neither minutes nor points" do
      let(:resource) { Hashie::Mash.new({ work_units: 30 }) }
      let(:issue_type) { Hashie::Mash.new }
      it "returns an empty hash" do
        expect(time_tracking_fields).to eq Hash.new
      end
    end
  end

  describe "#issue_epic_name_field" do
    let(:summary) { 'Issue summary' }
    let(:result) { service.send(:issue_epic_name_field, issue_type, summary) }
    context "when issue type has epic name field" do
      let(:issue_type) { Hashie::Mash.new(has_field_epic_name: true) }
      it "returns a specific hash" do
        service.stub(:meta_data).and_return(Hashie::Mash.new(epic_name_field: 'Some field'))
        expect(result).to eq(service.meta_data.epic_name_field => summary)
      end
    end

    context "when issue type doesn't have an epic name field" do
      let(:issue_type) { Hashie::Mash.new }
      it "returns an empty hash" do
        expect(result).to eq Hash.new
      end
    end
  end

  describe "#issue_epic_link_field" do
    let(:result) { service.send(:issue_epic_link_field, issue_type, parent, initiative) }
    let(:parent) { nil }
    before do
      service.stub(:meta_data).and_return(Hashie::Mash.new(epic_link_field: 'Epic link'))
    end
    context "when send_initiatives is set to true" do
      before do
        service.stub(:data).and_return(Hashie::Mash.new(send_initiatives: "1"))
      end
      context "when an initiative is present and issue type has an epic link field" do
        let(:initiative) { 'Some initiative' }
        let(:issue_type) { Hashie::Mash.new(has_field_epic_link: true) }
        it "returns a specific hash" do
          service.stub(:epic_key_for_initiative).and_return('New key')
          expect(result).to eq(service.meta_data.epic_link_field => 'New key')
        end
      end

      context "when the initiative and parent are not present" do
        let(:initiative) { nil }
        let(:issue_type) { Hashie::Mash.new }
        it "returns an empty hash" do
          expect(result).to eq Hash.new
        end
      end
    end

    context "when send_initiatives is not set to true" do
      let(:initiative) { 'Some initiative' }
      before do
        service.stub(:data).and_return(Hashie::Mash.new)
      end
      context "when parent is present and issue type has several fields" do
        let(:parent) { Hashie::Mash.new(key: 'Parent key') }
        let(:issue_type) { Hashie::Mash.new(has_field_epic_link: true) }
        let(:returned_issue_type) { Hashie::Mash.new(has_field_epic_name: true) }
        before do
          service.stub(:data).and_return(Hashie::Mash.new(feature_issue_type: 'Some type'))
          service.stub(:issue_type_by_id).and_return(returned_issue_type)
        end
        it "returns a specific hash" do
          expect(result).to eq(service.meta_data.epic_link_field => parent[:key])
        end
      end

      context "when parent is not present" do
        let(:parent) { nil }
        let(:issue_type) { Hashie::Mash.new }
        it "returns an empty hash" do
          expect(result).to eq Hash.new
        end
      end
    end
  end

  describe "#subtask_fields" do
    let(:parent) { nil }
    let(:subtask_fields) { service.send(:subtask_fields, is_subtask, parent) }
    shared_examples "empty subtask fields" do
      it "returns an empty hash" do
        expect(subtask_fields).to eq Hash.new
      end
    end

    context "when the issue is a subtask" do
      let(:is_subtask) { true }
      context "when a parent is supplied" do
        let(:parent) { { key: "Issue's parent" } }
        it "returns a specific hash" do
          expect(subtask_fields)
            .to eq(parent: { key: parent[:key] })
        end
      end

      context "when a parent is not supplied" do
        it_behaves_like "empty subtask fields"
      end
    end

    context "when the issue is not a subtask" do
      let(:is_subtask) { false }
      it_behaves_like "empty subtask fields"
    end
  end

  describe "#version_update_fields" do
    context "when a version exists" do
      let(:version) { Hashie::Mash.new(id: '1001') }
      context "when the issue type has field fix versions" do
        it "returns a specific hash" do
          issue_type = Hashie::Mash.new(has_field_fix_versions: true)
          expect(service.send(:version_update_fields, version, issue_type))
            .to eq(update: { fixVersions: [ { set: [ { id: version.id } ] } ] })
        end
      end
      context "when the issue type doesn't have field fix versions" do
        it "returns an empty hash" do
          issue_type = Hashie::Mash.new
          expect(service.send(:version_update_fields, nil, issue_type))
          .to eq Hash.new
        end
      end
    end

    context "when there is no version" do
      it "returns an empty hash" do
        expect(service.send(:version_update_fields, nil, Hashie::Mash.new))
          .to eq Hash.new
      end
    end
  end
end