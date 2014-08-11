require 'spec_helper'

describe AhaServices::Fogbugz do
  let(:service) do
    AhaServices::Fogbugz.new
  end
  let(:fogbugz_resource) { FogbugzResource.new(service) }
  let(:fogbugz_case_resource) { FogbugzCaseResource.new(service) }

  let(:projects) { Hashie::Mash.new(json_fixture("fogbugz/projects.json")).projects.project }
  let(:fogbugz_case) { Hashie::Mash.new(json_fixture("fogbugz/cases.json")['cases']) }
  let(:feature) { Hashie::Mash.new(name: 'First feature',
                                   description: { body: 'First feature description', attachments: [] },
                                   tags: [ 'First', 'Second', 'Third' ],
                                   resource: 'https://aha.aha.io/api/v1/feature/NBT-1-4') }
  let(:attachments_feature) { json_fixture("fogbugz/attachments.json") }
  let(:feature_with_requirements) { json_fixture("create_feature_event.json") }

  let(:response_error_xml) { '<?xml version="1.0" encoding="UTF-8"?><response><error code="3"><![CDATA[Not logged in]]></error></response>' }
  let(:new_parameters) do
    {
      sTitle: feature.name, 
      sEvent: Sanitize.fragment(feature.description.body).strip,
      sTags: feature.tags,
      ixProject: '1'
    } 
  end

  let (:edit_parameters) do
    {
      sTitle: feature.name, 
      sEvent: Sanitize.fragment(feature.description.body).strip,
      sTags: feature.tags,
      ixProject: '1',
      ixBug: '20'
    }
  end
  


  before do
    service.stub(:fogbugz_resource).and_return(fogbugz_resource)
    service.stub(:fogbugz_case_resource).and_return(fogbugz_case_resource)
    service.stub(:data).and_return(Hashie::Mash.new(projects: '1', api_token: 'token', fogbugz_url: 'https://fogbugz.com/'))
    service.stub(:integrate_resource_with_case).and_return(nil)
  end

  context "can be installed" do
    it "and handles installed event" do
      fogbugz_resource.should_receive(:projects).and_return(projects)
      service.receive(:installed)
      expect(service.meta_data.projects.sort_by(&:sProject).collect { |project| [project.sProject, project.ixProject] }).to eq [['Inbox', '2'], ['Sample Project', '1']]
    end
  end

  it "handles the 'create feature' event" do
    mock_payload = Hashie::Mash.new(feature: feature)
    service.stub(:payload).and_return(mock_payload)
    service.stub(:get_integration_field).and_return(nil)

  
    service.should_receive(:fetch_case_from_feature).with(mock_payload.feature).and_return(nil)
    fogbugz_case_resource.should_receive(:new_case).with(new_parameters, []).and_return(fogbugz_case)
    service.receive(:create_feature)
  end

  it "handles the 'create feature' event with requirements" do
    mock_payload = Hashie::Mash.new(feature_with_requirements)
    service.stub(:payload).and_return(mock_payload)
    service.stub(:get_integration_field).and_return(nil)

  
    service.should_receive(:fetch_case_from_feature).exactly(2).times
    fogbugz_case_resource.should_receive(:new_case).exactly(2).times.and_return(fogbugz_case)
    service.receive(:create_feature)
  end

  it "handles the 'update feature' event" do
    mock_payload = Hashie::Mash.new(feature: feature)
    service.stub(:payload).and_return(mock_payload)
    service.stub(:get_integration_field).and_return('20')
    
    service.should_receive(:fetch_case_from_feature).with(mock_payload.feature).and_return(fogbugz_case['case'])
    fogbugz_case_resource.should_receive(:edit_case).with(edit_parameters, []).and_return(fogbugz_case)
    service.receive(:update_feature)
  end

  it "handles attachments in 'create feature' event" do
    mock_payload = Hashie::Mash.new(attachments_feature)
    service.stub(:payload).and_return(mock_payload)
    service.stub(:get_integration_field).and_return(nil)

    service.should_receive(:fetch_case_from_feature).with(mock_payload.feature).and_return(nil)
    fogbugz_case_resource.should_receive(:new_case).with(new_parameters, [{:filename => 'a.png', :file_url => 'urla'}, {:filename => 'b.png', :file_url => 'urlb'}]).and_return(fogbugz_case)
    service.receive(:create_feature)
  end

  it "handles attachments in 'update feature' event" do
    mock_payload = Hashie::Mash.new(attachments_feature)
    service.stub(:payload).and_return(mock_payload)
    service.stub(:get_integration_field).and_return('20')

    service.should_receive(:fetch_case_from_feature).with(mock_payload.feature).and_return(fogbugz_case['case'])
    fogbugz_case_resource.should_receive(:edit_case).with(edit_parameters, [{:filename => 'a.png', :file_url => 'urla'}, {:filename => 'b.png', :file_url => 'urlb'}]).and_return(fogbugz_case)
    service.receive(:update_feature)
  end

  it "handles the 'webhook' event" do
    mock_payload = Hashie::Mash.new(case_number: '20')
    service.stub(:payload).and_return(mock_payload)

    service.should_receive(:fetch_case).with('20').and_return(fogbugz_case['case'])
    service.should_receive(:find_resource_with_case).with(fogbugz_case['case']).and_return(Hashie::Mash.new(feature: feature))
    service.should_receive(:update_resource).with('https://aha.aha.io/api/v1/feature/NBT-1-4', 'feature', 'Closed (Fixed)').and_return(nil)
    service.receive(:webhook)
  end

  it "raise an error when api returns an error" do
    mock_response = Hashie::Mash.new(body: response_error_xml)
    expect {
      fogbugz_resource.process_response(mock_response, 200)
    }.to raise_error(AhaService::RemoteError)
  end

  it "raise an error when not a 200 status" do
    mock_response = Hashie::Mash.new(status: 404, body: response_error_xml)
    expect {
      fogbugz_resource.process_response(mock_response, 200)
    }.to raise_error(AhaService::RemoteError)
  end

end
