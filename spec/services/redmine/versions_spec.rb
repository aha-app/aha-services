require 'spec_helper'

describe AhaServices::Redmine do

  context 'version creation' do
    let(:projects_index_raw) { raw_fixture('redmine/projects/index.json') }
    let(:projects_index_json) { JSON.parse projects_index_raw }
    let(:project_id) { projects_index_json['projects'].first['id'] }
    let(:version_name) { 'The Final Milestone' }
    let(:service) do
      described_class.new(
        { redmine_url: 'http://localhost:4000', project_id: project_id, api_key: '123456' },
        json_fixture('create_release_event.json'))
    end

    before do
      stub_aha_api_posts
    end

    context 'authenticated' do
      let(:raw_response) { raw_fixture('redmine/versions/create.json') }
      let(:json_response) { JSON.parse(raw_response) }
      let(:project) { service.meta_data.projects.find {|p| p[:id] == project_id }}

      it "responds to receive(:create_release)" do
        expect(service).to receive(:receive_create_release)
        service.receive(:create_release)
      end

      context 'no other versions previously installed' do
        before do
          stub_redmine_projects
          stub_request(:post, "#{service.data.redmine_url}/projects/#{project_id}/versions.json").
            to_return(status: 201, body: raw_response, headers: {})
        end

        it 'sends integration messages for release' do
          expect(service.api).to receive(:create_integration_field).with('OPS-R-1', 'redmine_issues', :id, anything).once
          expect(service.api).to receive(:create_integration_field).with('OPS-R-1', 'redmine_issues', :url, anything).once
          expect(service.api).to receive(:create_integration_field).with('OPS-R-1', 'redmine_issues', :name, anything).once
          service.receive(:create_release)
        end
      end
    end
  end

  context 'version update' do
    let(:project_id) { 2 }
    let(:version_id) { 2 }
    let(:project) { service.send :find_project, project_id }
    let(:new_version_name) { 'New Awesome Version Name' }
    let(:service) do
      described_class.new(
        { redmine_url: 'http://localhost:4000', api_key: '123456', project_id: project_id },
        json_fixture('update_release_event.json'))
    end

    it 'responds to receive(:update_release)' do
      expect(service).to receive(:receive_update_release)
      service.receive(:update_release)
    end

    before do
      populate_redmine_projects service
      stub_request(:put, "#{service.data.redmine_url}/projects/#{project_id}/versions/#{version_id}.json").
        to_return(status: 200, body: '{}', headers: {})
      stub_redmine_projects_and_versions
    end

    it 'reinstalls projects with versions' do
      expect(service).not_to receive(:create_integrations)
      expect(service).to receive(:http_put).and_call_original
      service.receive(:update_release)
    end
  end
end