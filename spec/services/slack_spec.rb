require "spec_helper"

describe AhaServices::Slack do
  describe "#send_message" do
    let(:service) { described_class.new }
    let(:message) { { some: :json } }

    before do
      allow(service).to receive(:url).and_return("some_url")
    end

    it "raises the entire error message when it's not JSON" do
      response = double("response", status: 500, body: "not JSON")

      expect(service).to receive(:http_post).and_return(response)
      expect {
        service.send(:send_message, message)
      }.to raise_error(/BODY=not JSON/)
    end

    it "returns the error.message when it's JSON" do
      response = double(
        "response",
        status: 500,
        body: { message: "JSON error" }.to_json
      )

      expect(service).to receive(:http_post).and_return(response)
      expect {
        service.send(:send_message, message)
      }.to raise_error(/BODY=JSON error/)
    end
  end
end
