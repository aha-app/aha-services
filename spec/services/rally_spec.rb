require "spec_helper"

# The following operations are supported:
#
# * Installing the service
# * Create a release
# * Update a release
# * Create a feature
# * Update a feature
# * Create a requirement
#
describe AhaServices::Rally do
  before do
    # stub_request(:get, //).
    #   to_return(status: 200, body: raw_fixture("rally/tbd.json"))
  end
  let(:service_params) do
    {}
  end

  let (:service) do
    AhaServices::Rally.new service_params
  end

  let(:h_req_service) do
    RallyHierarchicalRequirementResource.new service
  end

  it "can be installed"
  it "creates the right tag queries" do
    expect(h_req_service.send( :build_tag_query, ["1", "2", "3", "4", "5", "6"] ))
      .to eq '((((((Name = "1") OR (Name = "2")) OR (Name = "3")) OR (Name = "4")) OR (Name = "5")) OR (Name = "6"))'
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
