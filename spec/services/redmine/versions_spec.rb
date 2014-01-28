require 'spec_helper'

describe AhaServices::Redmine do

  # context 'project creation' do
  #   let(:project_name) { 'New Project' }
  #   let(:project_identifier) { 'new-project' }
  #   let(:service) do
  #     described_class.new(
  #       { redmine_url: 'http://localhost:4000', api_key: '123456' },
  #       { project_name: project_name }
  #     )
  #   end

  #   context 'authenticated' do
  #     let(:raw_response) { raw_fixture('redmine/projects/create.json') }
  #     let(:json_response) { JSON.parse(raw_response) }

  #     before do
  #       stub_request(:post, "#{service.data.redmine_url}/projects.json").
  #         to_return(status: 200, body: raw_response, headers: {})
  #     end

  #     it "responds to receive(:create_project)" do
  #       expect(service).to receive(:receive_create_project)
  #       service.receive(:create_project)
  #     end

  #     context 'no projects previously installed' do
  #       it "handles receive_create_project event" do
  #         service.receive(:create_project)
  #         new_project = service.meta_data.projects.last
  #         expect(service.meta_data.projects.size).to eq 1
  #         expect(new_project[:name]).to eq project_name
  #         expect(new_project[:id]).to eq json_response['project']['id']
  #       end
  #     end

  #     context 'some projects already installed' do
  #       let(:project_index_response_raw) { raw_fixture('redmine/projects/index.json') }
  #       before do
  #         stub_request(:get, "#{service.data.redmine_url}/projects.json").
  #           to_return(status: 200, body: project_index_response_raw, headers: {})
  #       end

  #       it "handles receive_create_project event" do
  #         service.receive(:installed)
  #         old_project_count = service.meta_data.projects.count
  #         service.receive(:create_project)
  #         new_project = service.meta_data.projects.last
  #         expect(service.meta_data.projects.size).to eq(1 + old_project_count)
  #         expect(new_project[:name]).to eq project_name
  #         expect(new_project[:id]).to eq json_response['project']['id']
  #       end
  #     end


  #   end

  #   context 'unauthenticated' do
  #     before do
  #       stub_request(:post, "#{service.data.redmine_url}/projects.json").
  #         to_return(status: 401, body: nil, headers: {})
  #     end

  #     it "responds to receive(:create_project)" do
  #       expect(service).to receive(:receive_create_project)
  #       service.receive(:create_project)
  #     end

  #     it "raises RemoteError" do
  #       expect { service.receive(:create_project) }.to raise_error(AhaService::RemoteError)
  #     end
  #   end
  # end

end