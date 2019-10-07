shared_context 'jira' do
  let(:integration_data) do
    {
      'projects' => [
        {
          'id' => '10000',
          'key' => 'DEMO',
          'name' => 'Aha! App Development',
          'issue_types' => '-3382654735848632001'
        }
      ],
      'epic_name_field' => 'customfield_10009',
      'epic_link_field' => 'customfield_10008',
      'aha_reference_field' => 'customfield_10206',
      'story_points_field' => 'customfield_10004',
      'fields' => {},
      'issue_type_sets' => {
        '-3382654735848632001' => [
          {
            'id' => '1',
            'name' => 'Bug',
            'subtask' => false,
            'has_field_fix_versions' => true,
            'has_field_aha_reference' => true,
            'has_field_story_points' => false,
            'has_field_epic_name' => false,
            'has_field_epic_link' => true,
            'has_field_labels' => true,
            'has_field_time_tracking' => true,
            'fields' => [
              'assignee',
              'attachment',
              'components',
              'customfield_10006',
              'customfield_10007',
              'customfield_10008',
              'customfield_10206',
              'customfield_10300',
              'description',
              'duedate',
              'environment',
              'fixVersions',
              'issuetype',
              'labels',
              'priority',
              'project',
              'reporter',
              'summary',
              'timetracking',
              'versions'
            ],
            'statuses' => '-2325688562603618987'
          },
          {
            'id' => '2',
            'name' => 'New Feature',
            'subtask' => false,
            'has_field_fix_versions' => true,
            'has_field_aha_reference' => true,
            'has_field_story_points' => false,
            'has_field_epic_name' => false,
            'has_field_epic_link' => true,
            'has_field_labels' => true,
            'has_field_time_tracking' => true,
            'fields' => [
              'assignee',
              'attachment',
              'components',
              'customfield_10006',
              'customfield_10007',
              'customfield_10008',
              'customfield_10206',
              'customfield_10300',
              'description',
              'duedate',
              'environment',
              'fixVersions',
              'issuetype',
              'labels',
              'priority',
              'project',
              'reporter',
              'summary',
              'timetracking',
              'versions'
            ],
            'statuses' => '-2325688562603618987'
          },
          {
            'id' => '3',
            'name' => 'Task',
            'subtask' => false,
            'has_field_fix_versions' => true,
            'has_field_aha_reference' => true,
            'has_field_story_points' => false,
            'has_field_epic_name' => false,
            'has_field_epic_link' => true,
            'has_field_labels' => true,
            'has_field_time_tracking' => true,
            'fields' => [
              'assignee',
              'attachment',
              'components',
              'customfield_10006',
              'customfield_10007',
              'customfield_10008',
              'customfield_10206',
              'customfield_10300',
              'description',
              'duedate',
              'environment',
              'fixVersions',
              'issuetype',
              'labels',
              'priority',
              'project',
              'reporter',
              'summary',
              'timetracking',
              'versions'
            ],
            'statuses' => '-2325688562603618987'
          },
          {
            'id' => '4',
            'name' => 'Improvement',
            'subtask' => false,
            'has_field_fix_versions' => true,
            'has_field_aha_reference' => true,
            'has_field_story_points' => false,
            'has_field_epic_name' => false,
            'has_field_epic_link' => true,
            'has_field_labels' => true,
            'has_field_time_tracking' => true,
            'fields' => [
              'assignee',
              'attachment',
              'components',
              'customfield_10006',
              'customfield_10007',
              'customfield_10008',
              'customfield_10206',
              'customfield_10300',
              'description',
              'duedate',
              'environment',
              'fixVersions',
              'issuetype',
              'labels',
              'priority',
              'project',
              'reporter',
              'summary',
              'timetracking',
              'versions'
            ],
            'statuses' => '-2325688562603618987'
          },
          {
            'id' => '5',
            'name' => 'Sub-task',
            'subtask' => true,
            'has_field_fix_versions' => true,
            'has_field_aha_reference' => true,
            'has_field_story_points' => false,
            'has_field_epic_name' => false,
            'has_field_epic_link' => true,
            'has_field_labels' => true,
            'has_field_time_tracking' => true,
            'fields' => [
              'assignee',
              'attachment',
              'components',
              'customfield_10006',
              'customfield_10007',
              'customfield_10008',
              'customfield_10206',
              'customfield_10300',
              'description',
              'duedate',
              'environment',
              'fixVersions',
              'issuetype',
              'labels',
              'parent',
              'priority',
              'project',
              'reporter',
              'summary',
              'timetracking',
              'versions'
            ],
            'statuses' => '-2325688562603618987'
          },
          {
            'id' => '6',
            'name' => 'Epic',
            'subtask' => false,
            'has_field_fix_versions' => true,
            'has_field_aha_reference' => true,
            'has_field_story_points' => true,
            'has_field_epic_name' => true,
            'has_field_epic_link' => true,
            'has_field_labels' => true,
            'has_field_time_tracking' => true,
            'fields' => [
              'assignee',
              'attachment',
              'components',
              'customfield_10004',
              'customfield_10006',
              'customfield_10007',
              'customfield_10008',
              'customfield_10009',
              'customfield_10206',
              'customfield_10300',
              'description',
              'duedate',
              'environment',
              'fixVersions',
              'issuetype',
              'labels',
              'priority',
              'project',
              'reporter',
              'summary',
              'timetracking',
              'versions'
            ],
            'statuses' => '-2325688562603618987'
          },
          {
            'id' => '7',
            'name' => 'User Story',
            'subtask' => false,
            'has_field_fix_versions' => true,
            'has_field_aha_reference' => true,
            'has_field_story_points' => true,
            'has_field_epic_name' => false,
            'has_field_epic_link' => true,
            'has_field_labels' => true,
            'has_field_time_tracking' => true,
            'fields' => [
              'assignee',
              'attachment',
              'components',
              'customfield_10004',
              'customfield_10006',
              'customfield_10007',
              'customfield_10008',
              'customfield_10206',
              'customfield_10300',
              'description',
              'duedate',
              'environment',
              'fixVersions',
              'issuetype',
              'labels',
              'priority',
              'project',
              'reporter',
              'summary',
              'timetracking',
              'versions'
            ],
            'statuses' => '-2325688562603618987'
          },
          {
            'id' => '8',
            'name' => 'Technical task',
            'subtask' => true,
            'has_field_fix_versions' => true,
            'has_field_aha_reference' => true,
            'has_field_story_points' => false,
            'has_field_epic_name' => false,
            'has_field_epic_link' => true,
            'has_field_labels' => true,
            'has_field_time_tracking' => true,
            'fields' => [
              'assignee',
              'attachment',
              'components',
              'customfield_10006',
              'customfield_10007',
              'customfield_10008',
              'customfield_10206',
              'customfield_10300',
              'description',
              'duedate',
              'environment',
              'fixVersions',
              'issuetype',
              'labels',
              'parent',
              'priority',
              'project',
              'reporter',
              'summary',
              'timetracking',
              'versions'
            ],
            'statuses' => '-2325688562603618987'
          }
        ]
      },
      'status_sets' => {
        '-2325688562603618987' => [
          {
            'id' => '1',
            'name' => 'Open'
          },
          {
            'id' => '3',
            'name' => 'In Progress'
          },
          {
            'id' => '4',
            'name' => 'Reopened'
          },
          {
            'id' => '5',
            'name' => 'Resolved'
          },
          {
            'id' => '6',
            'name' => 'Closed'
          }
        ],
        '3633375702085623271' => [
          {
            'id' => '1',
            'name' => 'Open'
          },
          {
            'id' => '10000',
            'name' => 'In QA'
          },
          {
            'id' => '3',
            'name' => 'In Progress'
          },
          {
            'id' => '4',
            'name' => 'Reopened'
          },
          {
            'id' => '5',
            'name' => 'Resolved'
          },
          {
            'id' => '6',
            'name' => 'Closed'
          }
        ]
      }
    }
  end

  let(:protocol) { 'http' }
  let(:server_url) { 'foo.com/a' }
  let(:api_url) { 'rest/api/2' }
  let(:username) { 'u' }
  let(:password) { 'p' }
  let(:base_url) { "#{protocol}://#{server_url}/#{api_url}" }
  let(:service_params) do
    {
      'server_url' => "#{protocol}://#{server_url}",
      'username' => username, 'password' => password,
      'project' => 'DEMO', 'feature_issue_type' => '6'
    }
  end
  let(:service) do
    AhaServices::Jira.new service_params
  end
end
