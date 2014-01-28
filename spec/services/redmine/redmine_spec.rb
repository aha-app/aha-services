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
        {type: :select, field_name: :version}
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

    context 'fresh installation' do
      let(:raw_response) { raw_fixture('redmine/projects/index.json') }
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

    context 'overwriting previous installation' do
      let(:raw_response_old_install) { raw_fixture('redmine/projects/index_2.json') }
      let(:raw_response_new_install) { raw_fixture('redmine/projects/index.json') }

      before do
        stub_request(:get, "#{service.data.redmine_url}/projects.json").
          to_return(status: 200, body: raw_response_old_install, headers: {})
        service.receive(:installed)
        stub_request(:get, "#{service.data.redmine_url}/projects.json").
          to_return(status: 200, body: raw_response_new_install, headers: {})
      end

      it "handles a second installed event" do
        expect(service.meta_data.projects.size).to eq(JSON.parse(raw_response_old_install)['projects'].size)

        service.receive(:installed)
        expect(service.meta_data.projects.size).to eq(JSON.parse(raw_response_new_install)['projects'].size)
      end
    end
  end
end