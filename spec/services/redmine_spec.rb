require 'spec_helper'

describe AhaServices::Redmine do
  before do
    IPSocket.stub(:getaddress).and_return '47.239.99.158'
    stub_download_feature_attachments
  end

  let(:service) do
    described_class.new(
      { redmine_url: 'http://api.my-redmine.org',
        project: project_id,
        api_key: '123456',
        integration_id: 111
      }, payload)
  end
  let(:projects_index_json) do
    page1 = JSON.parse(raw_fixture('redmine/projects/index1-page1.json'))
    page2 = JSON.parse(raw_fixture('redmine/projects/index1-page2.json'))
    page1["projects"].concat(page2["projects"])
    page1
  end
  let(:project_id) { 2 }
  let(:version_id) { 2 }

  shared_context 'RemoteError raiser' do |event|
    it "raises AhaService::RemoteError for #{event} event." do
      expect { service.receive(event) }.to raise_error(AhaService::RemoteError)
    end
  end

  def stub_redmine_versions **opts
    stub_request(opts[:method], "#{service.data.redmine_url}/projects/#{project_id}/versions.json").
      to_return(status: opts[:status], body: opts[:body], headers: {})
  end

  context 'class' do
    let(:title) { 'Redmine' }
    let(:service_name) { 'redmine' }
    let(:schema_fields) {[
      {type: :string, field_name: :redmine_url},
      {type: :string, field_name: :api_key},
      {type: :install_button, field_name: :install_button},
      {type: :select, field_name: :project},
      {type: :select, field_name: :tracker},
      {type: :select, field_name: :issue_priority} ]}

    it "has required title and name" do
      expect(described_class.title).to eq title
      expect(described_class.service_name).to eq service_name
    end

    it "has required schema fields" do
      expect(described_class.schema.map {|x| {type: x[0], field_name: x[1]}}).to eq schema_fields
    end
  end

  context 'installation' do
    let(:service) { described_class.new redmine_url: 'http://api.my-redmine.org', api_key: '123456' }
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
        stub_request(:get, "#{service.data.redmine_url}/projects.json?limit=100&offset=0").
          to_return(status: 404, body: '{"errors": ["Error 1", "Error 2"]}', headers: {})
      end
      it_behaves_like 'RemoteError raiser', :installed
    end
  end

  context 'release' do
    context 'creation' do
      let(:version_name) { 'The Final Milestone' }
      let(:payload) { json_fixture 'create_release_event.json' }
      before { stub_aha_api_posts; stub_redmine_projects }
      context 'auth errors' do
        before { stub_redmine_versions method: :post, status: 401, body: '{"errors": ["Error 1", "Error 2"]}' }
        it_behaves_like 'RemoteError raiser', :create_release
      end
      context 'param errors' do
        before do
          stub_request(:post, "#{service.data.redmine_url}/projects/#{project_id}/versions.json").
            to_return(status: 404, body: '{"errors": ["Error 1", "Error 2"]}', headers: {})
        end
        it_behaves_like 'RemoteError raiser', :create_release
      end
    end

    context 'update' do
      let(:new_version_name) { 'New Awesome Version Name' }
      let(:payload) { json_fixture 'update_release_event.json' }
      before { stub_redmine_projects }
      context 'with proper params' do
        before do
          populate_redmine_projects service
          stub_request(:put, "#{service.data.redmine_url}/versions/#{version_id}.json").
            to_return(status: 200, body: '{}', headers: {})
          stub_redmine_projects_and_versions
        end
        after {service.receive(:update_release)}
        context 'existing feature' do
          it 'updates redmine version' do
            expect_any_instance_of(RedmineVersionResource).to receive(:http_put).and_call_original
          end
        end
      end
      context 'auth errors' do
        before do
          stub_request(:put, "#{service.data.redmine_url}/versions/#{version_id}.json").
            to_return(status: 401, body: '{"errors": ["Error 1", "Error 2"]}', headers: {})
        end
        it_behaves_like 'RemoteError raiser', :update_release
      end
      context 'param errors' do
        before do
          stub_request(:put, "#{service.data.redmine_url}/versions/#{version_id}.json").
            to_return(status: 404, body: '{"errors": ["Error 1", "Error 2"]}', headers: {})
        end
        it_behaves_like 'RemoteError raiser', :update_release
      end
    end
  end

  context 'feature' do
    context 'creation' do
      let(:payload) { json_fixture 'create_feature_event.json' }
      before do
        stub_aha_api_posts
        populate_redmine_projects service
      end
      context 'authenticated' do
        context 'w/o version' do
          let(:issue_create_raw) { raw_fixture 'redmine/issues/create.json' }
          before do
            stub_request(:post, "#{service.data.redmine_url}/issues.json").
              to_return(status: 201, body: issue_create_raw, headers: {})
          end
          context 'w/o attachments' do
            let(:payload) { json_fixture 'create_feature_event_no_attach.json' }
            after { service.receive(:create_feature) }
            it 'posts attachment files for each attachment' do
              expect(service.api).to receive(:create_integration_fields).exactly(4)
              expect_any_instance_of(RedmineUploadResource).not_to receive(:upload_attachment)
              expect_any_instance_of(RedmineUploadResource).not_to receive(:http_post)
            end
            it 'sends attachment params while creating issue' do
              expect_any_instance_of(RedmineIssueResource).to receive(:http_post) do |_, url|
                expect(url).to eq('http://api.my-redmine.org/issues.json')
                double(status: 201, body: issue_create_raw)
              end.once
              expect_any_instance_of(RedmineIssueResource).to receive(:http_post).once.and_call_original
              expect(service.api).to receive(:create_integration_fields).exactly(4)
            end
          end
          context 'with attachments' do
            context 'proper params' do
              let(:upload_post_params) { ['http://api.my-redmine.org/uploads.json', anything] }
              before do
                stub_request(:post, "#{service.data.redmine_url}/uploads.json").
                  to_return(status: 201, body: raw_fixture('redmine/uploads/create.json'), headers: {})
              end
              after { service.receive(:create_feature) }
              it 'posts attachment files for each attachment' do
                expect(service.api).to receive(:create_integration_fields).exactly(4)
                expect_any_instance_of(RedmineUploadResource).to receive(:upload_attachment).at_least(:twice).and_call_original
                expect_any_instance_of(RedmineUploadResource).to receive(:http_post).with(*upload_post_params).at_least(:twice).and_call_original
              end
              it 'sends attachment params while creating issue' do
                expect_any_instance_of(RedmineIssueResource).to receive(:http_post) do |resource, url|
                  expect(url).to eq('http://api.my-redmine.org/issues.json')
                  double(status: 201, body: issue_create_raw)
                end.once
                expect_any_instance_of(RedmineIssueResource).to receive(:http_post).at_least(:once).and_call_original
                expect(service.api).to receive(:create_integration_fields).exactly(4)
              end
            end
            context 'unavailable tracker / project / other 404 generating errors' do
              before do
                stub_request(:post, "#{service.data.redmine_url}/issues.json").
                  to_return(status: 404, body: '{"errors": ["Error 1", "Error 2"]}', headers: {})
                stub_request(:post, "#{service.data.redmine_url}/uploads.json").
                  to_return(status: 204, body: raw_fixture('redmine/uploads/create.json'), headers: {})
              end
              it_behaves_like 'RemoteError raiser', :create_feature
            end
          end
        end
        context 'with version' do
          let(:issue_create_raw) { raw_fixture 'redmine/issues/create_with_version.json' }
          before do
            stub_request(:post, "#{service.data.redmine_url}/issues.json").
              to_return(status: 201, body: issue_create_raw, headers: {})
          end
          context 'w/o attachments' do
            let(:payload) { json_fixture 'create_feature_event_no_attach.json' }
            after { service.receive(:create_feature) }
            context 'proper params' do
              before do
                stub_request(:post, "#{service.data.redmine_url}/uploads.json").
                to_return(status: 201, body: raw_fixture('redmine/uploads/create.json'), headers: {})
              end
              let(:upload_post_params) { ['http://api.my-redmine.org/uploads.json', {file: anything}] }
              it 'posts attachment files for each attachment' do
                expect(service.api).to receive(:create_integration_fields).exactly(4)
                expect_any_instance_of(RedmineUploadResource).not_to receive(:upload_attachment)
                expect_any_instance_of(RedmineUploadResource).not_to receive(:http_post)
              end
              it 'sends attachment params while creating issue' do
                expect_any_instance_of(RedmineIssueResource).to receive(:http_post) do |params, url|
                  expect(url).to eq('http://api.my-redmine.org/issues.json')
                  double(status: 201, body: issue_create_raw)
                end.once
                expect_any_instance_of(RedmineIssueResource).to receive(:http_post).at_least(:once).and_call_original
                expect(service.api).to receive(:create_integration_fields).exactly(4)
              end
            end
          end
          context 'with attachments' do
            context 'proper params' do
              let(:upload_post_params) { ['http://api.my-redmine.org/uploads.json', anything] }
              before do
                stub_request(:post, "#{service.data.redmine_url}/uploads.json").
                  to_return(status: 201, body: raw_fixture('redmine/uploads/create.json'), headers: {})
              end
              after { service.receive(:create_feature) }
              it 'posts attachment files for each attachment' do
                expect(service.api).to receive(:create_integration_fields).exactly(4)
                expect_any_instance_of(RedmineUploadResource).to receive(:upload_attachment).at_least(:twice).and_call_original
                expect_any_instance_of(RedmineUploadResource).to receive(:http_post).with(*upload_post_params).at_least(:twice).and_call_original
              end
              it 'sends attachment params while creating issue' do
                expect_any_instance_of(RedmineIssueResource).to receive(:http_post) do |params, url|
                  expect(url).to eq('http://api.my-redmine.org/issues.json')
                  double(status: 201, body: issue_create_raw)
                end.once
                expect_any_instance_of(RedmineIssueResource).to receive(:http_post).at_least(:once).and_call_original
                expect(service.api).to receive(:create_integration_fields).exactly(4)
              end
            end
            context 'unavailable tracker / project / other 404 generating errors' do
              before do
                stub_request(:post, "#{service.data.redmine_url}/issues.json").
                  to_return(status: 404, body: '{"errors": ["Error 1", "Error 2"]}', headers: {})
                stub_request(:post, "#{service.data.redmine_url}/uploads.json").
                  to_return(status: 204, body: raw_fixture('redmine/uploads/create.json'), headers: {})
              end
              it_behaves_like 'RemoteError raiser', :create_feature
            end
          end
        end
      end
      context 'unauthenticated' do
        before do
          stub_request(:post, "#{service.data.redmine_url}/issues.json").
            to_return(status: 401, body: '{"errors": ["Error 1", "Error 2"]}', headers: {})
          stub_request(:post, "#{service.data.redmine_url}/uploads.json").
            to_return(status: 401, body: '{"errors": ["Error 1", "Error 2"]}', headers: {})
        end
        it_behaves_like 'RemoteError raiser', :create_feature
      end
    end

    context 'update' do
      before do
        stub_aha_api_posts
        populate_redmine_projects service
        stub_request(:put, /#{service.data.redmine_url}\/issues\/\d\.json/).
          to_return(status: 200, body: {}.to_json, headers: {})
        stub_request(:get, "http://api.my-redmine.org/issues/2.json?include=attachments").
          to_return(:status => 200, :body => Hashie::Mash.new(issue: { attachments: [] }).to_json, :headers => {})
        stub_request(:post, "#{service.data.redmine_url}/uploads.json").
          to_return(status: 200, body: raw_fixture('redmine/uploads/create.json'), headers: {})
        stub_request(:post, "#{service.data.redmine_url}/issues.json").
          to_return(status: 201, body: raw_fixture('redmine/issues/create.json'), headers: {})
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
            expect_any_instance_of(RedmineIssueResource).to receive(:http_put).with("#{service.data.redmine_url}/issues/2.json", anything).and_call_original
            service.receive(:update_feature)
          end
        end
        context 'w/o version' do
          let(:payload) do
            pload = json_fixture'update_feature_event.json'
            pload['feature']['release']['integration_fields'].reject! do |el|
              el['service_name'] == 'redmine' &&
              el['name'] == 'id'
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
            expect_any_instance_of(RedmineIssueResource).to receive(:http_put).with("#{service.data.redmine_url}/issues/2.json", anything).and_call_original
            service.receive(:update_feature)
          end
        end
      end
      context 'unauthenticated' do
        let(:payload) { json_fixture 'update_feature_event.json' }
        before do
          stub_request(:get, "#{service.data.redmine_url}/issues/2.json?include=attachments").
            to_return(status: 401, body: '{"errors": ["Error 1", "Error 2"]}', headers: {})
        end
        it_behaves_like 'RemoteError raiser', :update_feature
      end
    end
  end
end
