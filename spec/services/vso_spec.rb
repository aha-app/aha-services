require 'spec_helper'

describe AhaServices::VSO do
  let(:account_name) { "ahaintegration" }
  let(:project_id) { "43d47bf1-9c6c-4387-9945-944f625e60f3" }

  let(:api_url) { "https://#{account_name}.visualstudio.com/defaultcollection/_apis" }
  let(:api_url_project) { "https://#{account_name}.visualstudio.com/defaultcollection/#{project_id}/_apis" }

  let(:aha_api_url) { "https://a.aha.io/api/v1" }

  let :service do
    AhaServices::VSO.new({
      'account_name' => account_name,
      'project' => project_id
    }, nil, {})
  end


  before do
    service.data.stub(:feature_mapping).and_return("Feature")
    service.data.stub(:requirement_mapping).and_return("Requirement")
    service.data.stub(:area_path).and_return("Aha-Integration")

    stub_download_feature_attachments
  end
  
  context "when installing" do
    before do
      @stub_get_projects = stub_request(:get, "#{api_url}/projects?$top=1000&api-version=1.0").
                           to_return(:status => 200, :body => raw_fixture("tfs/tfs_get_projects.json"))
      @stub_get_project = stub_request(:get, "#{api_url}/projects/#{project_id}?api-version=1.0").
                          to_return(:status => 200, :body => raw_fixture("tfs/tfs_get_project.json"))
      @stub_get_workitemtypecategories = stub_request(:get, "#{api_url_project}/wit/workitemtypecategories?api-version=1.0").
                                         to_return(:status => 200, :body => raw_fixture("tfs/tfs_get_project_workitemtypecategories.json"))

      @stub_get_workitemtypes = stub_request(:get, "#{api_url_project}/wit/workitemtypes?api-version=1.0").
                                to_return(:status => 200, :body => raw_fixture("tfs/tfs_get_project_workitemtypes.json"))

      @stub_get_areas = stub_request(:get, "#{api_url_project}/wit/classificationNodes/areas?$depth=10&api-version=1.0").
                        to_return(:status => 200, :body => raw_fixture("tfs/tfs_get_project_areas.json"))
    end
    it "raises configuration error" do
      service = AhaServices::VSO.new({
        'account_name' => account_name,
        'project' => project_id
      }, nil, {})
      stub_request(:get, "#{api_url}/projects?$top=1000&api-version=1.0").
        to_return(:status => 401, :headers => {})
      expect {
        service.receive(:installed)
      }.to raise_error(AhaService::ConfigurationError)
    end

    it "fetches projects and workitemtypes" do
      service.receive(:installed)

      expect(service.meta_data[:projects].size).to be 1
      expect(service.meta_data[:projects][project_id]).to_not be_nil
      expect(service.meta_data[:workflow_sets].size).to be 1
    end
  end

  describe "recieving new feature" do
    let(:service) do
      AhaServices::VSO.new(
        {
          'account_name' => account_name, 
          'project' => project_id, 
          'integration_id' => 111
        }, json_fixture('create_feature_event.json'))
    end

    before do
      @create_workitem_feature = stub_request(:patch, "#{api_url_project}/wit/workitems/$Feature?api-version=1.0")
                                 .to_return(:status => 200, :headers => {}, :body => raw_fixture("tfs/tfs_create_feature.json"))
      @create_workitem_requirement = stub_request(:patch, "#{api_url_project}/wit/workitems/$Requirement?api-version=1.0")
                                     .to_return(:status => 200, :headers => {}, :body => raw_fixture("tfs/tfs_create_requirement.json"))
      @create_workitem_userstory = stub_request(:patch, "#{api_url_project}/wit/workitems/$User%20Story?api-version=1.0")
                                     .to_return(:status => 200, :headers => {}, :body => raw_fixture("tfs/tfs_create_requirement.json"))
      @link_workitem = stub_request(:patch, "#{api_url}/wit/workitems/175?api-version=1.0")
                       .to_return(:status => 200, :headers => {}, :body => raw_fixture("tfs/tfs_linked_feature.json"))
      @integrate_feature = stub_request(:post, "#{aha_api_url}/features/PROD-2/integrations/111/fields")
                           .to_return(:status => 201, :headers => {}, :body => "")
      @integrate_requirement = stub_request(:post, "#{aha_api_url}/requirements/PROD-2-1/integrations/111/fields")
                               .to_return(:status => 201, :headers => {}, :body => "")
      @upload_austria = stub_request(:post, "#{api_url}/wit/attachments?api-version=1.0&fileName=Austria.png")
                           .to_return(:status => 201, :headers => {}, :body => '{"id":"6b2266bf-a155-4582-a475-ca4da68193ef","url": "'+api_url+'/wit/attachments/6b2266bf-a155-4582-a475-ca4da68193ef?fileName=Austria.png"}')
      @upload_belgium = stub_request(:post, "#{api_url}/wit/attachments?api-version=1.0&fileName=Belgium.png")
                           .to_return(:status => 201, :headers => {}, :body => '{"id":"2ef0af3f-88e4-45f3-9f73-6d089aae0053","url": "'+api_url+'/wit/attachments/2ef0af3f-88e4-45f3-9f73-6d089aae0053?fileName=Belgium.png"}')
      @upload_finland = stub_request(:post, "#{api_url}/wit/attachments?api-version=1.0&fileName=Finland.png")
                           .to_return(:status => 201, :headers => {}, :body => '{"id":"2ef0af3f-88e4-45f3-9f73-6d089aae0053","url": "'+api_url+'/wit/attachments/2ef0af3f-88e4-45f3-9f73-6d089aae0053?fileName=Finland.png"}')
      @upload_france = stub_request(:post, "#{api_url}/wit/attachments?api-version=1.0&fileName=France.png")
                           .to_return(:status => 201, :headers => {}, :body => '{"id":"2ef0af3f-88e4-45f3-9f73-6d089aae0053","url": "'+api_url+'/wit/attachments/2ef0af3f-88e4-45f3-9f73-6d089aae0053?fileName=France.png"}')
      @link_attachment = stub_request(:patch, "#{api_url}/wit/workitems/174?api-version=1.0")
                         .to_return(:status => 200, :headers => {}, :body => "")
    end

    it "creates a new workitem" do
      service.receive(:create_feature)
      expect(@create_workitem_feature).to have_been_requested.once
      expect(@integrate_feature).to have_been_requested.once
      expect(@create_workitem_requirement).to have_been_requested.once
      expect(@link_workitem).to have_been_requested.times 3
      expect(@integrate_requirement).to have_been_requested.once
      expect(@upload_austria).to have_been_requested.once
      expect(@upload_belgium).to have_been_requested.once
      expect(@link_attachment).to have_been_requested.twice
    end

    context "when requirement mapped to user story" do
      it "creates a new user story" do
        service.data.stub(:requirement_mapping).and_return("User Story")
        service.receive(:create_feature)
        expect(@create_workitem_requirement).to_not have_been_requested
        expect(@create_workitem_userstory).to have_been_requested.once
      end
    end
    
  end
end
