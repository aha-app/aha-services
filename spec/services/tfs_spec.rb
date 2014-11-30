require 'spec_helper'

describe AhaServices::TFS do
  let(:account_name) { "ahaintegration" }
  let(:project) { "c0ec63a2-50a2-497f-aac8-743fd91e35d4" }

  let(:api_url) { "https://#{account_name}.visualstudio.com/defaultcollection/_apis/" }
  let(:api_url_project) { "https://#{account_name}.visualstudio.com/defaultcollection/#{project}/_apis/" }

  it "raises authentication error" do
    service = AhaServices::TFS.new({
      'account_name' => account_name,
      'project' => project,
      'user_name' => '',
      'user_password' => ''
    }, nil, {})
    stub_request(:get, "https://#{account_name}.visualstudio.com/defaultcollection/_apis/projects?api-version=1.0").
      to_return(:status => 200, :body => raw_fixture("tfs/tfs_get_projects.json"), :headers => {})
    expect {
      service.receive(:installed)
    }.to raise_error(AhaService::ConfigurationError)
  end
end
