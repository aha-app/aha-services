require 'spec_helper'

describe JiraProjectResource do
  include_context 'jira'

  subject(:resource) { described_class.new(service) }

  describe '#list' do
    subject(:list) { resource.list }

    def include_project(project)
      include(
        'id' => project['id'],
        'key' => project['key'],
        'name' => project['name']
      )
    end

    context 'when there is one page of results' do
      let(:projects) { json_fixture('jira/projects_all.json') }
      let(:project_stub) do
        stub_request(:get, "#{base_url}/project/search")
          .with(query: { 'startAt' => 0 })
          .to_return(status: 200, body: projects.to_json)
      end

      before { project_stub }

      it 'requests projects just once' do
        list
        expect(project_stub).to have_been_requested.once
      end

      it { is_expected.to include_project(projects['values'][0]) }
      it { is_expected.to include_project(projects['values'][1]) }
    end

    context 'when there are multiple pages of results' do
      let(:projects_page_1) { json_fixture('jira/projects_page_1.json') }
      let(:projects_page_2) { json_fixture('jira/projects_all.json') }
      let(:project_page_1_stub) do
        stub_request(:get, "#{base_url}/project/search")
          .with(query: { 'startAt' => 0 })
          .to_return(status: 200, body: projects_page_1.to_json)
      end
      let(:project_page_2_stub) do
        stub_request(:get, "#{base_url}/project/search")
          .with(query: { 'startAt' => 2 })
          .to_return(status: 200, body: projects_page_2.to_json)
      end

      before do
        project_page_1_stub
        project_page_2_stub
      end

      it 'requests the first page of projects' do
        list
        expect(project_page_1_stub).to have_been_requested.once
      end

      it 'requests the second page of projects' do
        list
        expect(project_page_2_stub).to have_been_requested.once
      end

      it { is_expected.to include_project(projects_page_1['values'][0]) }
      it { is_expected.to include_project(projects_page_1['values'][1]) }
      it { is_expected.to include_project(projects_page_2['values'][0]) }
      it { is_expected.to include_project(projects_page_2['values'][1]) }
    end

    context 'when there is an error' do
      before do
        stub_request(:get, "#{base_url}/project/search")
          .with(query: { 'startAt' => 0 })
          .to_return(status: status_code)
      end

      context 'with status 401' do
        let(:status_code) { 401 }

        it 'raises an auth error' do
          expect { list }.to raise_error(AhaService::RemoteError, /Authentication failed/)
        end
      end

      context 'with status 404' do
        let(:status_code) { 404 }

        let(:projects) { json_fixture('jira/projects_all.json')['values'] }
        let(:unpaginated_stub) do
          stub_request(:get, "#{base_url}/project")
            .to_return(status: 200, body: projects.to_json)
        end

        before { unpaginated_stub }

        it 'does not raise an error' do
          expect { list }.to_not raise_error
        end

        it 'falls back to the unpaginated endpoint' do
          list
          expect(unpaginated_stub).to have_been_requested
        end

        it { is_expected.to include_project(projects[0]) }
        it { is_expected.to include_project(projects[1]) }
      end
    end
  end
end
