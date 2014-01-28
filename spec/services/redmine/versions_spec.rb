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

      before do
        stub_request(:get, "#{service.data.redmine_url}/projects.json").
          to_return(status: 200, body: projects_index_raw, headers: {})
        stub_request(:post, "#{service.data.redmine_url}/projects/#{project_id}/versions.json").
          to_return(status: 201, body: raw_response, headers: {})
      end

      it "responds to receive(:create_version)" do
        expect(service).to receive(:receive_create_version)
        service.receive(:create_version)
      end

      context 'no other versions previously installed' do
        let(:new_version) { project[:versions].last }

        it "handles receive_create_version event" do
          service.receive(:create_version)

          expect(project[:versions].size).to eq 1
          expect(new_version[:name]).to eq version_name
          expect(new_version[:id]).to eq json_response['version']['id']
        end
      end

      context 'no other versions previously installed' do
        let(:new_version) { project[:versions].find {|v| v[:id] == json_response['version']['id'] }}

        it "handles receive_create_version event" do
          service.receive(:create_version)
          expect(project[:versions].size).to eq 1
          expect(new_version[:name]).to eq version_name
        end
      end

    end
  end
end