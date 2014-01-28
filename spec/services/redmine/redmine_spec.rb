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
      let(:projects_index_raw) { raw_fixture('redmine/projects/index.json') }
      let(:projects_index_json) { JSON.parse(projects_index_raw) }
      let(:versions_index_raw) { raw_fixture('redmine/versions/index.json') }
      let(:versions_index_json) { JSON.parse(versions_index_raw) }

      before do
        stub_redmine_projects_with_versions
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

      it 'installs versions for project 2' do
        service.receive(:installed)
        service.meta_data.projects.each_with_index do |proj|
          expect(proj[:versions].size).to eq((proj[:id] == 2) ? 3 : 0)
        end
      end
    end

    context 'overwriting previous installation' do
      let(:projects_index_more_raw) { raw_fixture('redmine/projects/index.json') }
      let(:projects_index_less_raw) { raw_fixture('redmine/projects/index_2.json') }

      let(:versions_index_more_raw) { raw_fixture('redmine/versions/index.json') }
      let(:versions_index_less_raw) { raw_fixture('redmine/versions/index_2.json') }

      context 'adding installations' do
        before do
          stub_redmine_projects_with_versions false, false
          service.receive(:installed)
          stub_redmine_projects_with_versions
        end

        it "installs new projects" do
          expect(service.meta_data.projects.size).to eq(JSON.parse(projects_index_less_raw)['projects'].size)
          service.receive(:installed)
          expect(service.meta_data.projects.size).to eq(JSON.parse(projects_index_more_raw)['projects'].size)
        end

        it "installs new versions" do
          service.meta_data.projects.each_with_index do |proj|
            expect(proj[:versions].size).to eq((proj[:id] == 2) ? 2 : 0)
          end
          service.receive(:installed)
          service.meta_data.projects.each_with_index do |proj|
            expect(proj[:versions].size).to eq((proj[:id] == 2) ? 3 : 0)
          end
        end
      end

      context 'reducing installations' do
        before do
          stub_redmine_projects_with_versions
          service.receive(:installed)
          stub_redmine_projects_with_versions false, false
        end

        it "installs new projects" do
          expect(service.meta_data.projects.size).to eq(JSON.parse(projects_index_more_raw)['projects'].size)
          service.receive(:installed)
          expect(service.meta_data.projects.size).to eq(JSON.parse(projects_index_less_raw)['projects'].size)
        end

        it "installs new versions" do
          service.meta_data.projects.each_with_index do |proj|
            expect(proj[:versions].size).to eq((proj[:id] == 2) ? 3 : 0)
          end
          service.receive(:installed)
          service.meta_data.projects.each_with_index do |proj|
            expect(proj[:versions].size).to eq((proj[:id] == 2) ? 2 : 0)
          end
        end
      end
    end
  end
end