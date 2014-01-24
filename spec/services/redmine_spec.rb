require 'spec_helper'

describe AhaServices::Redmine do
  context 'class' do
    let(:title) { 'Redmine' }
    let(:service_name) { 'redmine_issues' }
    let(:schema_fields) {
      [
        {type: :string, field_name: :redmine_url},
        {type: :string, field_name: :api_key},
        {type: :select, field_name: :project},
      ]
    }

    it "has required title and name" do
      expect(described_class.title).to eq title
      expect(described_class.service_name).to eq service_name
    end

    it "has required schema fields" do
      expect(
        described_class.schema.map {|x| {type: x[0], field_name: x[1]}}
      ).to eq schema_fields
    end
  end

  context "installation" do
    let(:service) { described_class.new redmine_url: 'http://localhost:4000', api_key: '123456' }

    context 'authenticated' do
      let(:raw_response) { raw_fixture('redmine/projects.json') }
      let(:json_response) { JSON.parse(raw_response) }

      before do
        stub_request(:get, "#{service.data.redmine_url}/projects.json").
          to_return(status: 200, body: raw_response, headers: {})
      end

      it "responds to receive(:installed)" do
        expect(service).to receive(:receive_installed)
        service.receive(:installed)
      end

      it "handles installed event" do
        service.receive(:installed)
        service.meta_data.projects.each_with_index do |proj, index|
          proj[:name].should == json_response['projects'][index]['name']
          proj[:id].should == json_response['projects'][index]['id']
        end
      end
    end
  end

  context 'project creation' do
    let(:project_name) { 'New Project' }
    let(:project_identifier) { 'new-project' }
    let(:service) { described_class.new redmine_url: 'http://localhost:4000', api_key: '123456' }

    context 'authenticated' do
      let(:raw_response) { raw_fixture('redmine/create_project.json') }
      let(:json_response) { JSON.parse(raw_response) }

      before do
        stub_request(:post, "#{service.data.redmine_url}/projects.json").
          to_return(status: 200, body: raw_response, headers: {})
      end

      it "responds to receive(:create_project)" do
        expect(service).to receive(:receive_create_project)
        service.receive(:create_project, project_name, project_identifier)
      end

      it "handles receive_create_project event" do
        service.receive(:create_project, project_name, project_identifier)
        new_project = service.meta_data.projects.last
        new_project[:name].should == project_name
        new_project[:id].should == json_response['project']['id']
      end
    end

    context 'unauthenticated' do
      pending
    end
  end


end