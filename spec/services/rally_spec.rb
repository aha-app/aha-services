require "spec_helper"
require "active_support/all"

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

  let(:meta_data) do
    Hashie::Mash.new({
      workspaces: [{
        name: "Test Workspace",
        ObjectID: 123,
        Configuration: {
          WorkspaceConfiguration: {
            TimeZone: "America/Chicago"
          }
        }
      }]
    })
  end

  let(:service_params) do
    {
      send_tags: "1",
      integration_id: "123",
      workspace: "123"
    }
  end

  let(:service_data) do
    Hashie::Mash.new service_params
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

    service = AhaServices::Rally.new service_params, Hashie::Mash.new(webhook_payload), meta_data
    service.instance_variable_set(:@api, api)
    service
  end

  let(:release) { Hashie::Mash.new(name: 'First release') }
  let(:feature) { Hashie::Mash.new name: 'First feature',
                                  workflow_status: {name: 'In development'},
                                  description: { body: 'First feature description' },
                                  release: release,
                                  tags: [ 'First', 'Second', 'Third', 'Aha!:First' ],
                                  requirements: [ { id: 'req_id' } ] }

  let (:feature_create_service) do
    api = Object.new
    service = AhaServices::Rally.new service_params, Hashie::Mash.new(feature: feature), meta_data
    service.instance_variable_set(:@api, api)
    service
  end

  let (:service) do
    AhaServices::Rally.new service_params
  end

  let(:h_req_service) do
    service.send(:rally_hierarchical_requirement_resource)
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
    webhook_service.update_record_from_webhook(webhook_payload, service_data)
  end

  it "can be installed" do
    AhaServices::Rally.new service_params
  end

  it "sets rank" do
    allow(h_req_service.api).to receive(:adjacent_integration_fields).
      and_return( [Hashie::Mash.new(json_fixture('rally/adjacent_integration_fields.json'))] )
    expect(h_req_service.send(:maybe_set_rank_for_feature, Hashie::Mash.new({}) )).to include("rankBelow")
  end

  it "Can update start and end dates to the right zone" do
    api = webhook_service.api
    expect(api).to receive(:put) do |_, update_hash|
      expect(update_hash["feature"][:due_date].to_s).to eql("2017-04-02")
    end

    webhook_service.update_record_from_webhook(webhook_payload, service_data)
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
    it "can be created" do
      h_req_service = feature_create_service.send(:rally_hierarchical_requirement_resource)
      token = SecureRandom.hex
      allow(h_req_service).to receive(:get_security_token).and_return(token)
      allow(h_req_service).to receive(:get_or_create_tag_references).and_return([{
        _ref: "https://example.com/tag/ref"
      }])

      create_url = "https://rally1.rallydev.com/slm/webservice/v2.0/hierarchicalrequirement/create?key=&workspace=https%3A%2F%2Frally1.rallydev.com%2Fslm%2Fwebservice%2Fv2.0%2Fworkspace%2F123"

      stub_response = Hashie::Mash.new({
        status: 200,
        body: {
          CreateResult: {
            Object: {
              object_id: "123"
            },
            Errors: []
          },
        }.to_json
      })

      expect(h_req_service.api).to receive(:create_integration_fields).and_return(true)
      expect(h_req_service).to receive(:create_attachments).and_return(true)
      expect(h_req_service).to receive(:update_from_feature).and_return(true)
      expect(h_req_service).to receive(:http_put).with(create_url, instance_of(String)).and_return(stub_response)

      feature_create_service.receive(:create_feature)
    end
    it "can be updated"
  end
end
