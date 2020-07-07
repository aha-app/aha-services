require "spec_helper"

describe PivotalTrackerStoryResource do
  let(:service) { double(data: double(mapping: "story-story", logger: double(debug: "", info: ""), api_client: double, api_token: "token", api_host: "example.com")) }
  let(:resource) { described_class.new(service, 1234) }

  describe "#update_from_resource" do
    let(:parent_mapping) { Hashie::Mash.new(id: 5678, label_id: 9012) }
    let(:resource_mapping) { Hashie::Mash.new(id: 9876, name: "test") }

    it "handles a missing story" do
      resource.stub(:find_by_id).and_return(nil)
      resource.stub(:name).and_return("testing")
      resource.stub(:description).and_return(Hashie::Mash.new(body: "description of body", attachments: []))
      resource.stub(:work_units).and_return(0)
      resource.stub(:attachments).and_return([])

      stub_request(:put, "https://example.com/services/v5/projects/1234/stories/9876")
        .to_return(:status => 200, :body => "")
      stub_request(:get, "https://example.com/services/v5/projects/1234/stories/9876/comments?fields=file_attachments").
        to_return(:status => 200, :body => "")

      updated_story = resource.update_from_feature(resource_mapping, resource, parent_mapping)
      expect(updated_story).to eql("")
    end
  end
end
