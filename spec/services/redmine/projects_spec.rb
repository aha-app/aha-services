require 'spec_helper'

describe AhaServices::Redmine do
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
      let(:raw_response) { raw_fixture('redmine/projects/create.json') }
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

      context 'some projects already installed' do
        let(:project_index_response_raw) { raw_fixture('redmine/projects/index.json') }
        before do
          stub_redmine_projects
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
    let(:project_index_response_raw) { raw_fixture('redmine/projects/index.json') }
    let(:project_index_response_json) { JSON.parse(project_index_response_raw) }
    let(:project_id) { project_index_response_json['projects'].last['id'] }
    let(:project_name) { 'NewAwesomeProjectName' }
    let(:service) do
      described_class.new(
        { redmine_url: 'http://localhost:4000', api_key: '123456' },
        { id: project_id,
          project_name: project_name
        })
    end

    before do
      stub_redmine_projects
      stub_request(:put, "#{service.data.redmine_url}/projects/#{project_id}.json").
        to_return(status: 200, body: '{}', headers: {})
      service.receive(:installed)
    end

    context 'authenticated' do
      context 'edited_project is installed' do
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

      context 'edited_project is not installed' do
        it 'creates the missing edited_project' do
          service.meta_data.projects.pop
          old_project_count = service.meta_data.projects.size
          service.receive(:update_project)
          expect(service.meta_data.projects.size).to eq(1 + old_project_count)
        end
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

  context 'project deletion' do
    let(:project_index_response_raw) { raw_fixture('redmine/projects/index.json') }
    let(:project_index_response_json) { JSON.parse(project_index_response_raw) }
    let(:project_id) { project_index_response_json['projects'].last['id'] }
    let(:service) do
      described_class.new(
        { redmine_url: 'http://localhost:4000', api_key: '123456' },
        { id: project_id })
    end

    before do
      stub_redmine_projects
      stub_request(:delete, "#{service.data.redmine_url}/projects/#{project_id}.json").
        to_return(status: 200, body: '{}', headers: {})
      service.receive(:installed)
    end

    context 'authenticated' do
      it "responds to receive(:delete_project)" do
        expect(service).to receive(:receive_delete_project)
        service.receive(:delete_project)
      end

      it "handles receive_update_project event" do
        service.receive(:delete_project)
        expect(service.meta_data['projects'].find {|p| p[:id] == project_id}).to be_nil
      end
    end

    context 'unauthenticated' do
      before do
        stub_request(:delete, "#{service.data.redmine_url}/projects/#{project_id}.json").
          to_return(status: 401, body: '{}', headers: {})
        service.receive(:installed)
      end

      it "handles receive_update_project event" do
        expect { service.receive(:delete_project) }.to raise_error(AhaService::RemoteError)
      end
    end
  end
end