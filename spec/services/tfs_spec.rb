require "spec_helper"

# The following operations are supported:
#
# * Installing the service
# * Retreiving the list of projects
# * Retreiving a specific project
# * Retreiving the list of work item type categories for a project
# * Retreiving the list of work item types for a project
# * Creating a work item feature
# * Creating a work item requirement
# * Creating a work item user story
# * Uploading attachments
#
describe AhaServices::TFS do
  def stub_requests
    # TODO - Copied these URLs from VSO. Validate that they're correct for TFS.

    # Projects
    stub_request(:get, /.*_apis\/projects\?.*/).
      to_return(status: 200, body: raw_fixture("tfs/tfs_get_projects.json"))

    # Project
    stub_request(:get, /.*_apis\/projects\/#{@project_id}\?.*/).
      to_return(status: 200, body: raw_fixture("tfs/tfs_get_project.json"))

    # Work Item Type Categories
    stub_request(:get, /.*#{@project_id}\/_apis\/wit\/workitemtypecategories.*/).
      to_return(status: 200, body: raw_fixture("tfs/tfs_get_project_workitemtypecategories.json"))

    # Work Item Types
    stub_request(:get, /.*#{@project_id}\/_apis\/wit\/workitemtypes.*/).
      to_return(status: 200, body: raw_fixture("tfs/tfs_get_project_workitemtypes.json"))

    # Areas
    stub_request(:get, /.*#{@project_id}\/_apis\/wit\/classificationNodes\/areas.*/).
      to_return(status: 200, body: raw_fixture("tfs/tfs_get_project_areas.json"))
  end

  before do
    # TODO - Copied these credentials from VSO. Validate that they're correct for TFS.
    @account_name = "ahaintegration"
    @project_id = "43d47bf1-9c6c-4387-9945-944f625e60f3"
  end

  it "can be installed" do
    stub_requests

    service = AhaServices::VSO.new(
      { account_name: @account_name, project: @project_id },
      nil,
      {}
    )

    service.receive(:installed)
    expect(service.meta_data[:projects]).to have_key(@project_id)
  end

  context "project" do
    it "can be updated"
    it "can be destroyed"
  end

  context "release" do
    it "can be created"
    it "can be updated"
  end

  context "feature" do
    it "can be created"
    it "can be updated"
  end
end
