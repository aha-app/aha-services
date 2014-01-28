require 'spec_helper'

describe AhaServices::Redmine do

  context 'version creation' do
    let(:projects_index_raw) { raw_fixture('redmine/projects/index.json') }
    let(:projects_index_json) { JSON.parse projects_index_raw }
    let(:project_id) { projects_index_json['projects'].first['id'] }
    let(:version_name) { 'The Final Milestone' }
    let(:version_identifier) { 'the-final-milestone' }
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
      # let(:raw_response) { raw_fixture('redmine/projects/create.json') }
      # let(:json_response) { JSON.parse(raw_response) }

      before do
        stub_request(:post, "#{service.data.redmine_url}/projects/#{project_id}/versions.json").
          to_return(status: 200, body: {}, headers: {})
      end

      it "responds to receive(:create_version)" do
        expect(service).to receive(:receive_create_version)
        service.receive(:create_version)
      end

      context 'no other versions previously installed' do
        it "handles receive_create_version event" do
          service.receive(:create_version)
          new_version = service.meta_data.versions.last
          expect(service.meta_data.versions.size).to eq 1
          expect(new_version[:name]).to eq project_name
          # expect(new_version[:id]).to eq json_response['project']['id']
        end
      end

    end
  end
end