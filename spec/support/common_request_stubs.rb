def stub_aha_api_posts
  stub_request(:post, /https\:\/\/a\.aha\.io\/api\/v1\/(features|requirements|releases)\/[\w\d\-]*\/integrations\/[\w\d\-_]*\/fields/).
    to_return(:status => 200, :body => "", :headers => {})
end

def stub_download_feature_attachments
  # Download attachments.
  stub_request(:get, "https://attachments.s3.amazonaws.com/attachments/6cce987f6283d15c080e53bba15b1072a7ab5b07/original.png?1370457053").
    to_return(:status => 200, :body => "aaaaaa", :headers => {})
  stub_request(:get, "https://attachments.s3.amazonaws.com/attachments/d1cb788065a70dad7ba481c973e19dcd379eb202/original.png?1370457055").
    to_return(:status => 200, :body => "bbbbbb", :headers => {})
  stub_request(:get, "https://attachments.s3.amazonaws.com/attachments/80641a3d3141ce853ea8642bb6324534fafef5b3/original.png?1370458143").
    to_return(:status => 200, :body => "cccccc", :headers => {})
  stub_request(:get, "https://attachments.s3.amazonaws.com/attachments/6fad2068e2aa0e031643d289367263d3721c8683/original.png?1370458145").
    to_return(:status => 200, :body => "dddddd", :headers => {})
end

def stub_redmine_projects more_projects=true
  projects_index_raw = more_projects ? raw_fixture('redmine/projects/index.json') : raw_fixture('redmine/projects/index_2.json')

  stub_request(:get, "#{service.data.redmine_url}/projects.json").
    to_return(status: 200, body: projects_index_raw, headers: {})
  stub_request(:get, "#{service.data.redmine_url}/projects/1/versions.json").
    to_return(status: 200, body: {}, headers: {})
  stub_request(:get, "#{service.data.redmine_url}/projects/2/versions.json").
    to_return(status: 200, body: {}, headers: {})
  stub_request(:get, "#{service.data.redmine_url}/projects/3/versions.json").
    to_return(status: 200, body: {}, headers: {})
end

def stub_redmine_projects_and_versions more_projects=true, more_versions=true
  projects_index_raw = more_projects ? raw_fixture('redmine/projects/index.json') : raw_fixture('redmine/projects/index_2.json')
  versions_index_raw = more_versions ? raw_fixture('redmine/versions/index.json') : raw_fixture('redmine/versions/index_2.json')

  stub_request(:get, "#{service.data.redmine_url}/projects.json").
    to_return(status: 200, body: projects_index_raw, headers: {})
  stub_request(:get, "#{service.data.redmine_url}/projects/1/versions.json").
    to_return(status: 200, body: {}, headers: {})
  stub_request(:get, "#{service.data.redmine_url}/projects/2/versions.json").
    to_return(status: 200, body: versions_index_raw, headers: {})
  stub_request(:get, "#{service.data.redmine_url}/projects/3/versions.json").
    to_return(status: 200, body: {}, headers: {})
end

def populate_redmine_projects service, more_projects=true
  stub_redmine_projects more_projects
  service.receive(:installed)
end