require "spec_helper"

describe AhaServices::MicrosoftTeams do
  describe "#send_message" do
    let(:service) { described_class.new }
    let(:message) { { some: :json } }
    let(:url) { "some_url" }

    before do
      allow(service).to receive(:url).and_return(url)
    end

    context "when URL is not configured" do
      before do
        allow(service).to receive(:url).and_return(nil)
      end

      it "raises an error" do
        expect {
          service.send_message(message)
        }.to raise_error(AhaService::RemoteError, "Integration has not been configured")
      end
    end

    context "when the response is successful" do
      [200, 201, 202, 204].each do |status|
        it "returns successfully for status #{status}" do
          response = double("response", status: status)
          expect(service).to receive(:http_post).and_return(response)
          expect { service.send_message(message) }.not_to raise_error
        end
      end
    end

    context "when the response is a known error" do
      it "raises an error for 'Webhook Bad Request - Null or empty event'" do
        response = double("response", status: 400, body: 'Webhook Bad Request - Null or empty event')
        expect(service).to receive(:http_post).and_return(response)
        expect {
          service.send_message(message)
        }.to raise_error(AhaService::RemoteError, "Please use the Microsoft Teams Webhook connector (not the Aha! connector) for this integration.")
      end

      it "raises an error for 'Connector configuration not found'" do
        response = double("response", status: 400, body: "Connector configuration not found")
        expect(service).to receive(:http_post).and_return(response)
        expect {
          service.send_message(message)
        }.to raise_error(AhaService::RemoteError, "The connector configuration was not found")
      end

      it "raises an error for a 404 status" do
        response = double("response", status: 404, body: "Not Found")
        expect(service).to receive(:http_post).and_return(response)
        expect {
          service.send_message(message)
        }.to raise_error(AhaService::RemoteError, "URL is not recognized")
      end
    end

    context "when the response is an unhandled error" do
      it "raises the entire error message when it's not JSON" do
        response = double("response", status: 500, body: "not JSON")
        expect(service).to receive(:http_post).and_return(response)
        expect {
          service.send_message(message)
        }.to raise_error(/BODY=not JSON/)
      end

      it "returns the error.message when it's JSON" do
        response = double("response", status: 500, body: { message: "JSON error" }.to_json)
        expect(service).to receive(:http_post).and_return(response)
        expect {
          service.send_message(message)
        }.to raise_error(/BODY=JSON error/)
      end
    end
  end

  describe "#workflow_webhook?" do
    it "returns true when integration_method is workflow" do
      allow(subject).to receive(:data).and_return(double(integration_method: "workflow"))
      expect(subject.send(:workflow_webhook?)).to be_truthy
    end

    it "returns false when integration_method is not workflow" do
      allow(subject).to receive(:data).and_return(double(integration_method: "connector"))
      expect(subject.send(:workflow_webhook?)).to be_falsey
    end
  end

  describe "#connector_message" do
    it "constructs a connector message correctly" do
      payload = double(audit: double(created_at: Time.now, auditable_url: "http://example.com", user: nil, description: "did something", changes: []))
      allow(subject).to receive(:payload).and_return(payload)
      allow(subject).to receive(:title).and_return("Aha! did something")
      allow(subject).to receive(:audit_time).and_return("2024-08-23 3:45 PM")

      expected_message = {
        "@type": "MessageCard",
        "@context": "http://schema.org/extensions",
        "themeColor": "0073CF",
        "Summary": "Aha! did something",
        "sections": [{
          "activityTitle": "Aha! did something",
          "activitySubtitle": "2024-08-23 3:45 PM",
          "facts": [],
          "markdown": true
        }],
        "potentialAction": [
          {
            "@type": "OpenUri",
            "name": "View in Aha!",
            "targets": [
              {
                "os": "default",
                "uri": "http://example.com"
              }
            ]
          }
        ]
      }

      expect(subject.send(:connector_message)).to eq(expected_message)
    end
  end

  describe "#workflow_message" do
    it "constructs a workflow message correctly" do
      payload = double(audit: double(created_at: Time.now, auditable_url: "http://example.com", user: nil, description: "did something", changes: []))
      allow(subject).to receive(:payload).and_return(payload)
      allow(subject).to receive(:title).and_return("Aha! did something")
      allow(subject).to receive(:audit_time).and_return("2024-08-23 3:45 PM")

      expected_message = {
        "attachments": [
          {
            "contentType": "application/vnd.microsoft.card.adaptive",
            "contentUrl": nil,
            "content": {
              "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
              "type": "AdaptiveCard",
              "version": "1.2",
              "body": [
                {
                  "type": "TextBlock",
                  "text": "Aha! did something",
                  "weight": "bolder",
                  "size": "medium",
                  "wrap": true,
                  "style": "heading"
                },
                {
                  "type": "TextBlock",
                  "text": "2024-08-23 3:45 PM",
                  "weight": "lighter",
                  "size": "small",
                  "wrap": true
                },
                {
                  "type": "FactSet",
                  "facts": []
                }
              ],
              "actions": [
                {
                  "type": "Action.OpenUrl",
                  "title": "View in Aha!",
                  "url": "http://example.com"
                }
              ]
            }
          }
        ]
      }

      expect(subject.send(:workflow_message)).to eq(expected_message)
    end

    it "converts html to markdown" do
      audited_changes = [
        { "title" => "Description", "value" => "<div>Some description</div>" },
      ]
      payload = double(audit: double(created_at: Time.now, auditable_url: "http://example.com", user: nil, description: "did something", changes: audited_changes))
      allow(subject).to receive(:payload).and_return(payload)
      allow(subject).to receive(:title).and_return("Aha! did something")
      allow(subject).to receive(:audit_time).and_return("2024-08-23 3:45 PM")

      fact =  subject.send(:workflow_message)[:attachments][0][:content][:body].last[:facts][0]
      expect(fact["title"]).to eq("Description")
      expect(fact["value"]).to eq("Some description\n")
    end

    it "can handle integers as the audited change value" do
      audited_changes = [
        { "title" => "Estimate", "value" => 5 },
      ]
      payload = double(audit: double(created_at: Time.now, auditable_url: "http://example.com", user: nil, description: "did something", changes: audited_changes))
      allow(subject).to receive(:payload).and_return(payload)
      allow(subject).to receive(:title).and_return("Aha! did something")
      allow(subject).to receive(:audit_time).and_return("2024-08-23 3:45 PM")

      fact = subject.send(:workflow_message)[:attachments][0][:content][:body].last[:facts][0]
      expect(fact["title"]).to eq("Estimate")
      expect(fact["value"]).to eq(5)
    end
  end
end
