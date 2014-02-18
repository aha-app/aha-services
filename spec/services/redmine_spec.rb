require 'spec_helper'

describe AhaServices::Redmine do
  before do
    IPSocket.stub(:getaddress).and_return '47.239.99.158'
    stub_download_feature_attachments
  end

  let(:service) do
    described_class.new(
      { redmine_url: 'http://api.my-redmine.org',
        project_id: project_id,
        api_key: '123456'
      }, payload)
  end
  let(:projects_index_raw) { raw_fixture('redmine/projects/index.json') }
  let(:projects_index_json) { JSON.parse(projects_index_raw) }

  context 'class' do
    let(:title) { 'Redmine' }
    let(:service_name) { 'redmine_issues' }
    let(:schema_fields) {
      [
        {type: :install_button, field_name: :install_button},
        {type: :string, field_name: :redmine_url},
        {type: :string, field_name: :api_key},
        {type: :select, field_name: :project}
      ]}

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

  context 'installation' do
    let(:service) { described_class.new redmine_url: 'http://api.my-redmine.org', api_key: '123456' }

    it "responds to receive(:installed)" do
      expect(service).to receive(:receive_installed)
      service.receive(:installed)
    end

    context 'fresh installation' do
      before { stub_redmine_projects }

      it 'installs projects' do
        service.receive(:installed)
        service.meta_data.projects.each_with_index do |proj, index|
          expect(proj[:name]).to eq projects_index_json['projects'][index]['name']
          expect(proj[:id]).to eq projects_index_json['projects'][index]['id']
        end
      end
    end

    context 'overwriting' do
      before do
        populate_redmine_projects service, false
        stub_redmine_projects
      end

      it 'overwrites projects' do
        expect(service.meta_data.projects.size).to eq 2
        service.receive(:installed)
        expect(service.meta_data.projects.size).to eq 3
        service.meta_data.projects.each_with_index do |proj, index|
          expect(proj[:name]).to eq projects_index_json['projects'][index]['name']
          expect(proj[:id]).to eq projects_index_json['projects'][index]['id']
        end
      end
    end

    context 'redmine failsafe' do
      before do
        stub_request(:get, "#{service.data.redmine_url}/projects.json").
          to_return(status: 404, body: {}, headers: {})
      end

      it 'raises AhaService::RemoteError' do
        expect { service.receive(:installed) }.to raise_error(AhaService::RemoteError)
      end
    end
  end

  context 'release' do
    context 'creation' do
      let(:project_id) { projects_index_json['projects'].first['id'] }
      let(:version_name) { 'The Final Milestone' }
      let(:payload) { json_fixture 'create_release_event.json' }

      before do
        stub_aha_api_posts
      end

      it "responds to receive(:create_release)" do
        expect(service).to receive(:receive_create_release)
        service.receive(:create_release)
      end

      context 'with proper params' do
        let(:raw_response) { raw_fixture('redmine/versions/create.json') }
        let(:project) { service.meta_data.projects.find {|p| p[:id] == project_id }}

        before do
          stub_redmine_projects
          stub_request(:post, "#{service.data.redmine_url}/projects/#{project_id}/versions.json").
            to_return(status: 201, body: raw_response, headers: {})
        end

        it 'sends integration messages for release' do
          expect(service.api).to receive(:create_integration_field).with('release', 'OPS-R-1', 'redmine_issues', :id, anything).once
          expect(service.api).to receive(:create_integration_field).with('release', 'OPS-R-1', 'redmine_issues', :url, anything).once
          expect(service.api).to receive(:create_integration_field).with('release', 'OPS-R-1', 'redmine_issues', :name, anything).once
          service.receive(:create_release)
        end
      end

      context 'auth errors' do
        before do
          stub_redmine_projects
          stub_request(:post, "#{service.data.redmine_url}/projects/#{project_id}/versions.json").
            to_return(status: 401, body: {}, headers: {})
        end

        it 'raises AhaService::RemoteError' do
          expect { service.receive(:create_release) }.to raise_error(AhaService::RemoteError)
        end
      end

      context 'param errors' do
        before do
          stub_redmine_projects
          stub_request(:post, "#{service.data.redmine_url}/projects/#{project_id}/versions.json").
            to_return(status: 404, body: {}, headers: {})
        end

        it 'raises AhaService::RemoteError' do
          expect { service.receive(:create_release) }.to raise_error(AhaService::RemoteError)
        end
      end
    end

    context 'update' do
      let(:project_id) { 2 }
      let(:version_id) { 2 }
      let(:project) { service.send :find_project, project_id }
      let(:new_version_name) { 'New Awesome Version Name' }
      let(:payload) { json_fixture 'update_release_event.json' }

      it 'responds to receive(:update_release)' do
        expect(service).to receive(:receive_update_release)
        service.receive(:update_release)
      end

      context 'with proper params' do
        before do
          populate_redmine_projects service
          stub_request(:put, "#{service.data.redmine_url}/projects/#{project_id}/versions/#{version_id}.json").
            to_return(status: 200, body: '{}', headers: {})
          stub_redmine_projects_and_versions
        end

        context 'existing feature' do
          it 'updates redmine version' do
            expect(service.api).to receive(:create_integration_field).exactly(3)
            expect_any_instance_of(RedmineVersionResource).to receive(:http_put).and_call_original
            service.receive(:update_release)
          end

          it 'updates feature integration' do
            expect(service.api).to receive(:create_integration_field).with('release', 'OPS-R-1', 'redmine_issues', :id, anything).once
            expect(service.api).to receive(:create_integration_field).with('release', 'OPS-R-1', 'redmine_issues', :url, anything).once
            expect(service.api).to receive(:create_integration_field).with('release', 'OPS-R-1', 'redmine_issues', :name, anything).once
            service.receive(:update_release)
          end
        end
      end

      context 'auth errors' do
        before do
          stub_redmine_projects
          stub_request(:put, "#{service.data.redmine_url}/projects/#{project_id}/versions/#{version_id}.json").
            to_return(status: 401, body: {}, headers: {})
        end

        it 'raises AhaService::RemoteError' do
          expect { service.receive(:update_release) }.to raise_error(AhaService::RemoteError)
        end
      end

      context 'param errors' do
        before do
          stub_redmine_projects
          stub_request(:put, "#{service.data.redmine_url}/projects/#{project_id}/versions/#{version_id}.json").
            to_return(status: 404, body: {}, headers: {})
        end

        it 'raises AhaService::RemoteError' do
          expect { service.receive(:update_release) }.to raise_error(AhaService::RemoteError)
        end
      end
    end
  end

  context 'feature' do
    context 'creation' do
      let(:project_id) { 2 }
      let(:payload) { json_fixture 'create_feature_event.json' }
      before do
        stub_aha_api_posts
        populate_redmine_projects service
      end
      it "responds to receive(:create_feature)" do
        expect(service).to receive(:receive_create_feature)
        service.receive(:create_feature)
      end
      context 'authenticated' do
        shared_context 'sends proper integration fields' do
          it 'sends integration messages for issue' do
            expect(service.api).to receive(:create_integration_field).with('feature', "PROD-2", "redmine_issues", :id, anything).once
            expect(service.api).to receive(:create_integration_field).with('feature', "PROD-2", "redmine_issues", :url, anything).once
            expect(service.api).to receive(:create_integration_field).with('feature', "PROD-2", "redmine_issues", :name, anything).once
            expect(service.api).to receive(:create_integration_field).exactly(3)
            service.receive(:create_feature)
          end
          it 'sends integration messages for requirement' do
            expect(service.api).to receive(:create_integration_field).with('requirement', "PROD-2-1", "redmine_issues", :id, anything).once
            expect(service.api).to receive(:create_integration_field).with('requirement', "PROD-2-1", "redmine_issues", :url, anything).once
            expect(service.api).to receive(:create_integration_field).with('requirement', "PROD-2-1", "redmine_issues", :name, anything).once
            expect(service.api).to receive(:create_integration_field).exactly(3)
            service.receive(:create_feature)
          end
        end
        context 'w/o version' do
          let(:issue_create_raw) { raw_fixture 'redmine/issues/create.json' }
          before do
            stub_request(:post, "#{service.data.redmine_url}/projects/#{project_id}/issues.json").
              to_return(status: 201, body: issue_create_raw, headers: {})
          end
          context 'w/o attachments' do
            let(:payload) { json_fixture 'create_feature_event_no_attach.json' }
            it 'posts attachment files for each attachment' do
              expect(service.api).to receive(:create_integration_field).exactly(6)
              expect_any_instance_of(RedmineUploadResource).not_to receive(:upload_attachment)
              expect_any_instance_of(RedmineUploadResource).not_to receive(:http_post)
              service.receive(:create_feature)
            end
            it 'sends attachment params while creating issue' do
              expect_any_instance_of(RedmineIssueResource).to receive(:http_post) do |url, params|
                expect(url).to match(/http:\/\/api.my-redmine.org\/projects\/\d*\/issues.json/)
                issue_json = JSON.parse(params)['issue']
                expect(issue_json.keys).to include('tracker_id','subject')
                expect(issue_json.keys).not_to include('uploads')
                double(status: 201, body: issue_create_raw)
              end.once
              expect_any_instance_of(RedmineIssueResource).to receive(:http_post).once.and_call_original
              expect(service.api).to receive(:create_integration_field).exactly(6)
              service.receive(:create_feature)
            end
            it_behaves_like 'sends proper integration fields'
          end
          context 'with attachments' do
            context 'proper params' do
              let(:upload_post_params) { ['http://api.my-redmine.org/uploads.json', {file: anything}] }
              before do
                stub_request(:post, "#{service.data.redmine_url}/uploads.json").
                  to_return(status: 201, body: raw_fixture('redmine/uploads/create.json'), headers: {})
              end
              it 'posts attachment files for each attachment' do
                expect(service.api).to receive(:create_integration_field).exactly(6)
                expect_any_instance_of(RedmineUploadResource).to receive(:upload_attachment).twice.and_call_original
                expect_any_instance_of(RedmineUploadResource).to receive(:http_post).with(*upload_post_params).twice.and_call_original
                service.receive(:create_feature)
              end
              it 'sends attachment params while creating issue' do
                expect_any_instance_of(RedmineIssueResource).to receive(:http_post) do |url, params|
                  expect(url).to match(/http:\/\/api.my-redmine.org\/projects\/\d*\/issues.json/)
                  issue_json = JSON.parse(params)['issue']
                  expect(issue_json.keys).to include('tracker_id','subject', 'uploads')
                  issue_json['uploads'].each do |upload|
                    expect(upload.keys).to include('token','filename', 'content_type')
                  end
                  double(status: 201, body: issue_create_raw)
                end.once
                expect_any_instance_of(RedmineIssueResource).to receive(:http_post).once.and_call_original
                expect(service.api).to receive(:create_integration_field).exactly(6)
                service.receive(:create_feature)
              end
              it_behaves_like 'sends proper integration fields'
            end
            context 'unavailable tracker / project / other 404 generating errors' do
              before do
                stub_request(:post, "#{service.data.redmine_url}/projects/#{project_id}/issues.json").
                  to_return(status: 404, body: '', headers: {})
                stub_request(:post, "#{service.data.redmine_url}/uploads.json").
                  to_return(status: 204, body: raw_fixture('redmine/uploads/create.json'), headers: {})
              end

              it "raises error" do
                expect(service.api).not_to receive(:create_integration_field)
                expect { service.receive(:create_feature) }.to raise_error(AhaService::RemoteError)
              end

            end
          end
        end

        context 'with version' do
          before { populate_redmine_projects service }
          context 'available tracker' do
            let(:issue_create_raw) { raw_fixture 'redmine/issues/create_with_version.json' }
            before do
              stub_request(:post, "#{service.data.redmine_url}/projects/#{project_id}/issues.json").
                to_return(status: 201, body: issue_create_raw, headers: {})
              stub_request(:post, "#{service.data.redmine_url}/uploads.json").
                to_return(status: 201, body: raw_fixture('redmine/uploads/create.json'), headers: {})
            end

            it 'sends integration messages for issue' do
              expect(service.api).to receive(:create_integration_field).with('feature', 'PROD-2', 'redmine_issues', :id, anything).once
              expect(service.api).to receive(:create_integration_field).with('feature', 'PROD-2', 'redmine_issues', :url, anything).once
              expect(service.api).to receive(:create_integration_field).with('feature', 'PROD-2', 'redmine_issues', :name, anything).once
              expect(service.api).to receive(:create_integration_field).exactly(6)
              service.receive(:create_feature)
            end
            it 'sends integration messages for release' do
              expect(service.api).to receive(:create_integration_field).with('release', 'PROD-R-1', 'redmine_issues', :id, anything).once
              expect(service.api).to receive(:create_integration_field).with('release', 'PROD-R-1', 'redmine_issues', :url, anything).once
              expect(service.api).to receive(:create_integration_field).with('release', 'PROD-R-1', 'redmine_issues', :name, anything).once
              expect(service.api).to receive(:create_integration_field).exactly(6)
              service.receive(:create_feature)
            end
            it 'sends integration messages for requirement' do
              expect(service.api).to receive(:create_integration_field).with('requirement', 'PROD-2-1', 'redmine_issues', :id, anything).once
              expect(service.api).to receive(:create_integration_field).with('requirement', 'PROD-2-1', 'redmine_issues', :url, anything).once
              expect(service.api).to receive(:create_integration_field).with('requirement', 'PROD-2-1', 'redmine_issues', :name, anything).once
              expect(service.api).to receive(:create_integration_field).exactly(6)
              service.receive(:create_feature)
            end
          end
        end
      end

      context 'unauthenticated' do
        before do
          stub_request(:post, "#{service.data.redmine_url}/projects/#{project_id}/issues.json").
            to_return(status: 401, body: {}, headers: {})
          stub_request(:post, "#{service.data.redmine_url}/uploads.json").
            to_return(status: 401, body: raw_fixture('redmine/uploads/create.json'), headers: {})
        end
        it 'rasies error' do
          expect { service.receive(:create_feature) }.to raise_error(AhaService::RemoteError)
        end
      end
    end

    context 'update' do
      let(:project_id) { 2 }
      before do
        stub_aha_api_posts
        populate_redmine_projects service
        stub_request(:put, /#{service.data.redmine_url}\/projects\/#{project_id}\/issues\/\d\.json/).
          to_return(status: 201, body: {}, headers: {})
      end

      context 'authenticated' do
        context 'with version' do
          let(:payload) { json_fixture 'update_feature_event.json' }
          let(:params) do
            { issue: {
                tracker_id: 2,
                subject: "Feature with attachments (new)",
                fixed_version_id: '2'
            }}.to_json
          end

          it 'sends PUT to redmine with proper params' do
            expect_any_instance_of(RedmineIssueResource).to receive(:http_put).with(anything, params).and_call_original
            service.receive(:update_feature)
          end
        end

        context 'w/o version' do
          let(:payload) do
            pload = json_fixture'update_feature_event.json'
            pload['feature']['integration_fields'].reject! do |el|
              el['service_name'] == 'redmine_issues' &&
              el['name'] == 'version_id'
            end
            pload
          end
          let(:params) do
            { issue: {
                tracker_id: 2,
                subject: "Feature with attachments (new)"
            }}.to_json
          end

          it 'sends PUT to redmine with proper params' do
            expect_any_instance_of(RedmineIssueResource).to receive(:http_put).with(anything, params).and_call_original
            service.receive(:update_feature)
          end
        end
      end

      context 'unauthenticated' do
        let(:payload) { json_fixture 'update_feature_event.json' }
        before do
          stub_request(:put, /#{service.data.redmine_url}\/projects\/#{project_id}\/issues\/\d\.json/).
            to_return(status: 401, body: {}, headers: {})
        end
        it 'rasies error' do
          expect { service.receive(:update_feature) }.to raise_error(AhaService::RemoteError)
        end
      end
    end
  end
end