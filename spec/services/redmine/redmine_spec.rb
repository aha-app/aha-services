require 'spec_helper'

describe AhaServices::Redmine do
  context 'class' do
    let(:title) { 'Redmine' }
    let(:service_name) { 'redmine_issues' }
    let(:schema_fields) {
      [
        {type: :string, field_name: :redmine_url},
        {type: :string, field_name: :api_key},
        {type: :select, field_name: :project}]}

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
      let(:projects_index_raw) { raw_fixture('redmine/projects/index.json') }
      let(:projects_index_json) { JSON.parse(projects_index_raw) }

      before do
        stub_redmine_projects
      end

      it "responds to receive(:installed)" do
        expect(service).to receive(:receive_installed)
        service.receive(:installed)
      end

      it "installs projects" do
        service.receive(:installed)
        service.meta_data.projects.each_with_index do |proj, index|
          expect(proj[:name]).to eq projects_index_json['projects'][index]['name']
          expect(proj[:id]).to eq projects_index_json['projects'][index]['id']
        end
      end
    end
  end
end