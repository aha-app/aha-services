require 'spec_helper'

class FogbugzApi
  def command(command, opts = {}, attachments = [])
    if :listProjects
      json_fixture("fogbugz/projects.json")
    elsif :search
      if opts['q'] == 'case:20'
        json_fixture("fogbugz/cases.json")
      else
        nil
      end
    elsif :new

    elsif :edit

    end
  end
end

describe AhaServices::Fogbugz do
  let(:service) do
    AhaServices::Fogbugz.new
  end
  let(:api) { FogbugzApi.new }
  let(:fogbugz_case) { json_fixture("fogbugz/cases.json")['cases'] }
  let(:feature) { Hashie::Mash.new(name: 'First feature',
                                   description: { body: 'First feature description', attachments: [] },
                                   tags: [ 'First', 'Second', 'Third' ]) }
  let(:attachments_feature) { json_fixture("fogbugz/attachments.json") }
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

  let(:file_like_object) { double("file like object") }
  


  before do
    service.stub(:fogbugz_api).and_return(api)
    service.stub(:data).and_return(Hashie::Mash.new(projects: '1'))
    service.stub(:integrate_resource_with_case).and_return(nil)
    service.stub(:open).and_return(file_like_object)
  end

  context "can be installed" do
    it "and handles installed event" do
      service.receive(:installed)
      expect(service.meta_data.projects.collect(&:sProject).sort).to eq ['Inbox', 'Sample Project']
    end
  end

  it "handles the 'create feature' event" do
    mock_payload = Hashie::Mash.new(feature: feature)
    service.stub(:payload).and_return(mock_payload)
    service.stub(:get_integration_field).and_return(nil)

  
    service.should_receive(:fetch_case).with(mock_payload.feature).and_return(nil)
    api.should_receive(:command).with(:new, new_parameters, []).and_return(fogbugz_case)
    service.receive(:create_feature)
  end

  it "handles the 'update feature' event" do
    mock_payload = Hashie::Mash.new(feature: feature)
    service.stub(:payload).and_return(mock_payload)
    service.stub(:get_integration_field).and_return('20')
    
    service.should_receive(:fetch_case).with(mock_payload.feature).and_return(fogbugz_case['case'])
    api.should_receive(:command).with(:edit, edit_parameters, []).and_return(fogbugz_case)
    service.receive(:update_feature)
  end

  it "handles attachments in 'create feature' event" do
    mock_payload = Hashie::Mash.new(attachments_feature)
    service.stub(:payload).and_return(mock_payload)
    service.stub(:get_integration_field).and_return(nil)

    service.should_receive(:fetch_case).with(mock_payload.feature).and_return(nil)
    api.should_receive(:command).with(:new, new_parameters, [{:filename => 'a.png', :file => file_like_object}, {:filename => 'b.png', :file => file_like_object}]).and_return(fogbugz_case)
    service.receive(:create_feature)
  end

    it "handles attachments in 'update feature' event" do
    mock_payload = Hashie::Mash.new(attachments_feature)
    service.stub(:payload).and_return(mock_payload)
    service.stub(:get_integration_field).and_return('20')

    service.should_receive(:fetch_case).with(mock_payload.feature).and_return(fogbugz_case['case'])
    api.should_receive(:command).with(:edit, edit_parameters, [{:filename => 'a.png', :file => file_like_object}, {:filename => 'b.png', :file => file_like_object}]).and_return(fogbugz_case)
    service.receive(:update_feature)
  end
end
