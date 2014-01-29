require 'spec_helper'

describe AhaServices::Redmine do

  context 'version creation' do
    let(:projects_index_raw) { raw_fixture('redmine/projects/index.json') }
    let(:projects_index_json) { JSON.parse projects_index_raw }
    let(:project_id) { projects_index_json['projects'].first['id'] }
    let(:version_name) { 'The Final Milestone' }
    let(:service) do
      described_class.new(
        { redmine_url: 'http://localhost:4000', api_key: '123456' },
        {
          project_id: project_id,
          version_name: version_name
        }
      )
    end

    context 'authenticated' do
      let(:raw_response) { raw_fixture('redmine/versions/create.json') }
      let(:json_response) { JSON.parse(raw_response) }
      let(:project) { service.meta_data.projects.find {|p| p[:id] == project_id }}

      it "responds to receive(:create_version)" do
        expect(service).to receive(:receive_create_version)
        service.receive(:create_version)
      end

      context 'no other versions previously installed' do
        before do
          stub_redmine_projects_without_versions
          stub_request(:post, "#{service.data.redmine_url}/projects/#{project_id}/versions.json").
            to_return(status: 201, body: raw_response, headers: {})
        end
        let(:new_version) { project[:versions].last }

        it "handles receive_create_version event" do
          service.receive(:create_version)
          expect(project[:versions].size).to eq 1
          expect(new_version[:name]).to eq version_name
          expect(new_version[:id]).to eq json_response['version']['id']
        end
      end

      context 'some other versions previously installed' do
        before do
          stub_redmine_projects_with_versions
          stub_request(:post, "#{service.data.redmine_url}/projects/#{project_id}/versions.json").
            to_return(status: 201, body: raw_response, headers: {})
        end
        let(:new_version) { project[:versions].find {|v| v[:id] == json_response['version']['id'] }}

        it "handles receive_create_version event" do
          service.receive(:create_version)
          expect(project[:versions].size).to eq 1
          expect(new_version[:name]).to eq version_name
        end
      end

    end
  end

  context 'version update' do
    let(:project_id) { 2 }
    let(:version_id) { 1 }
    let(:project) { service.send :find_project, project_id }
    let(:version) { service.send :find_version, project_id, version_id }
    let(:new_version_name) { 'New Awesome Version Name' }
    let(:service) do
      described_class.new(
        { redmine_url: 'http://localhost:4000', api_key: '123456' },
        { project_id: project_id,
          version_id: version_id,
          version: {name: new_version_name}
        })
    end

    it 'responds to receive(:update_version)' do
      expect(service).to receive(:receive_update_version)
      service.receive(:update_version)
    end

    context 'installed version' do
      before do
        stub_redmine_projects_with_versions
        stub_request(:put, "#{service.data.redmine_url}/projects/#{project_id}/versions/#{version_id}.json").
          to_return(status: 200, body: '{}', headers: {})
        service.receive(:installed)
      end

      it 'updates the version`s name' do
        service.receive(:update_version)
        expect(version[:name]).to eq new_version_name
      end
    end

    context 'not installed version' do
      before do
        stub_redmine_projects_without_versions
        stub_request(:put, "#{service.data.redmine_url}/projects/#{project_id}/versions/#{version_id}.json").
          to_return(status: 200, body: '{}', headers: {})
        service.receive(:installed)
        stub_redmine_projects_with_versions
      end

      it 'reinstalls projects with versions' do
        expect(service).to receive(:install_projects)
        service.receive(:update_version)
      end
    end
  end

  context 'version delete' do
    let(:project_id) { 2 }
    let(:version_id) { 1 }
    let(:project) { service.send :find_project, project_id }
    let(:version) { service.send :find_version, project_id, version_id }
    let(:service) do
      described_class.new(
        { redmine_url: 'http://localhost:4000', api_key: '123456' },
        { project_id: project_id,
          version_id: version_id
        })
    end

    it 'responds to receive(:delete_version)' do
      expect(service).to receive(:receive_delete_version)
      service.receive(:delete_version)
    end

    context 'installed version' do
      before do
        stub_redmine_projects_with_versions
        stub_request(:delete, "#{service.data.redmine_url}/projects/#{project_id}/versions/#{version_id}.json").
          to_return(status: 200, body: '{}', headers: {})
        service.receive(:installed)
      end

      it 'deletes version' do
        old_version_count = project[:versions].size
        service.receive(:delete_version)
        expect(version).to be_nil
        expect(project[:versions].size).to eq(old_version_count - 1)
      end
    end
  end
end