require "spec_helper"

RSpec.describe FogbugzResource do
  let(:resource) do
    described_class.new(service)
  end
  
  let(:service) do
    AhaServices::Fogbugz.new 'fogbugz_url' => fogbugz_url
  end
  
  describe "#api_url" do
    subject { resource.api_url }
    
    context "https://fogbuz.com" do
      let(:fogbugz_url) { "https://fogbugz.com" }
      it { is_expected.to eq "https://fogbugz.com/api.asp?cmd=" }
    end
    
    context "https://custom.domain/fogbugz" do
      let(:fogbugz_url) { "https://custom.domain/fogbugz" }
      it { is_expected.to eq "https://custom.domain/fogbugz/api.asp?cmd=" }
    end
  end
end