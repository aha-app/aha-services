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

  let(:webhook_payload) do
    Hashie::Mash.new JSON.parse(fixture("rally/rally_update_webhook.json").read)
  end

  let(:integration_fields) do
    integration_fields = Hashie::Mash.new JSON.parse(fixture("rally/aha_integration_fields.json").read)
  end

  let (:webhook_service) do
    api = Object.new
    allow(api).to receive(:search_integration_fields).and_return(integration_fields)

    service = AhaServices::Rally.new service_params
    service.instance_variable_set(:@payload, Hashie::Mash.new(webhook_payload))
    service.instance_variable_set(:@api, api)
    service
  end

  let (:service) do
    AhaServices::Rally.new service_params
  end

  let(:h_req_service) do
    RallyHierarchicalRequirementResource.new service
  end



  it "creates the right tag queries" do
    expect(h_req_service.send( :build_tag_query, ["1", "2", "3", "4", "5", "6"] ))
      .to eq '((((((Name = "1") OR (Name = "2")) OR (Name = "3")) OR (Name = "4")) OR (Name = "5")) OR (Name = "6"))'

    expect(h_req_service.send( :build_tag_query, ["1"] ))
      .to eq '(Name = "1")'
  end

  it "adds tags" do
    api = webhook_service.api
    expect(api).to receive(:put) { |_, update_hash| expect(update_hash["feature"][:tags]).to be_present }
    webhook_service.update_record_from_webhook(webhook_payload)
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
