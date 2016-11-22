require "spec_helper"

describe PivotalTrackerProjectDependentResource do
  let(:service) { double(data: double(mapping: "story-story", logger: double, api_client: double)) }
  let(:resource) { described_class.new(service, 1234) }

  describe "#create_from_requirement" do
    it "appends the requirement description when not present" do
      expect(resource.send(:append_link, "foo", 5678)).to eql("foo\n\nRequirement of #5678.")
    end

    it "does not append the requirement description when it's already there" do
      initial_body = "Some existing text.\n\nRequirement of #5678"
      processed_body = resource.send(:append_link, initial_body, 5678)

      expect(initial_body).to eql(processed_body)
    end
  end
end
