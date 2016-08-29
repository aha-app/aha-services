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

  it "can be installed"

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
