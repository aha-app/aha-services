require 'spec_helper'

describe AhaServices::AuditWebhook do
  describe "#validate_cert" do
    let(:service) do
      AhaServices::AuditWebhook.new(validate_cert: "1")
    end

    it "validates the cert" do
      expect(service.http.ssl.verify).to be true
    end
  end
end
