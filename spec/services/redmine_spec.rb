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
          expect(proj[:name]).to eq json_response['projects'][index]['name']
          expect(proj[:id]).to eq json_response['projects'][index]['id']
        end
      end
    end
  end

  context 'project creation' do
    let(:project_name) { 'New Project' }
    let(:project_identifier) { 'new-project' }
    let(:service) do
      described_class.new(
        { redmine_url: 'http://localhost:4000', api_key: '123456' },
        { project_name: project_name }
      )
    end

    context 'authenticated' do
      let(:raw_response) { raw_fixture('redmine/create_project.json') }
      let(:json_response) { JSON.parse(raw_response) }

      before do
        stub_request(:post, "#{service.data.redmine_url}/projects.json").
          to_return(status: 200, body: raw_response, headers: {})
      end

      it "responds to receive(:create_project)" do
        expect(service).to receive(:receive_create_project)
        service.receive(:create_project)
      end

      context 'no projects previously installed' do
        it "handles receive_create_project event" do
          service.receive(:create_project)
          new_project = service.meta_data.projects.last
          expect(service.meta_data.projects.size).to eq 1
          expect(new_project[:name]).to eq project_name
          expect(new_project[:id]).to eq json_response['project']['id']
        end
      end

      context 'some projects already isntalled' do
        let(:project_index_response_raw) { raw_fixture('redmine/projects.json') }
        before do
          stub_request(:get, "#{service.data.redmine_url}/projects.json").
            to_return(status: 200, body: project_index_response_raw, headers: {})
        end

        it "handles receive_create_project event" do
          service.receive(:installed)
          old_project_count = service.meta_data.projects.count
          service.receive(:create_project)
          new_project = service.meta_data.projects.last
          expect(service.meta_data.projects.size).to eq(1 + old_project_count)
          expect(new_project[:name]).to eq project_name
          expect(new_project[:id]).to eq json_response['project']['id']
        end
      end


    end

    context 'unauthenticated' do
      before do
        stub_request(:post, "#{service.data.redmine_url}/projects.json").
          to_return(status: 401, body: nil, headers: {})
      end

      it "responds to receive(:create_project)" do
        expect(service).to receive(:receive_create_project)
        service.receive(:create_project)
      end

      it "raises RemoteError" do
        expect { service.receive(:create_project) }.to raise_error(AhaService::RemoteError)
      end
    end
  end

  context 'project update' do
    let(:project_index_response_raw) { raw_fixture('redmine/projects.json') }
    let(:project_index_response_json) { JSON.parse(project_index_response_raw) }
    let(:project_id) { project_index_response_json['projects'].last['id'] }
    let(:project_name) { 'NewAwesomeProjectName' }
    let(:project_identifier) { 'newawesomeprojectname' }
    let(:service) do
      described_class.new(
        { redmine_url: 'http://localhost:4000', api_key: '123456' },
        { id: project_id,
          project_name: project_name
        })
    end

    before do
      stub_request(:get, "#{service.data.redmine_url}/projects.json").
        to_return(status: 200, body: project_index_response_raw, headers: {})
    end

    context 'authenticated' do
      before do
        stub_request(:put, "#{service.data.redmine_url}/projects/#{project_id}.json").
          to_return(status: 200, body: '{}', headers: {})
        service.receive(:installed)
      end

      it "responds to receive(:update_project)" do
        expect(service).to receive(:receive_update_project)
        service.receive(:update_project)
      end

      it "handles receive_update_project event" do
        service.receive(:update_project)
        edited_project = service.meta_data['projects'].find {|p| p[:id] == project_id}
        expect(edited_project[:name]).to eq project_name
      end
    end

    context 'unauthenticated' do
      before do
        stub_request(:put, "#{service.data.redmine_url}/projects/#{project_id}.json").
          to_return(status: 401, body: '{}', headers: {})
        service.receive(:installed)
      end

      it "handles receive_update_project event" do
        edited_project = service.meta_data['projects'].find {|p| p[:id] == project_id}
        old_name = edited_project[:name]
        expect { service.receive(:update_project) }.to raise_error(AhaService::RemoteError)
        expect(edited_project[:name]).to eq old_name
        expect(edited_project[:name]).not_to eq project_name
      end
    end
  end


end