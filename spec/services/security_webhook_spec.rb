require 'spec_helper'

describe AhaServices::SecurityWebhook do
  describe "#validate_cert" do
    let(:service) do
      AhaServices::SecurityWebhook.new(validate_cert: "1")
    end

    it "validates the cert" do
      expect(service.http.ssl.verify).to be true
    end
  end
end
