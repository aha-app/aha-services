require "spec_helper"

describe AhaServices::Trello do
  let(:base_url) { "https://api.trello.com/1" }
  let(:service) do
    AhaServices::Trello.new 'server_url' => base_url
  end

  it "can receive new features" do
    service.stub(:payload)
      .and_return(Hashie::Mash.new(json_fixture("create_feature_event.json")))
    service.should_receive(:create_or_update_trello_card)
    service.receive(:create_feature)
  end

  it "can update existing features" do
    service.stub(:payload)
      .and_return(Hashie::Mash.new(json_fixture("update_feature_event.json")))
    service.should_receive(:create_or_update_trello_card)
    service.receive(:update_feature)
  end
end
