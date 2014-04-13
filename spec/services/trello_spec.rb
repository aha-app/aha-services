require "spec_helper"

describe AhaServices::Trello do
  let(:base_url) { "https://api.trello.com/1" }
  let(:oauth_key) { "my_key" }
  let(:oauth_token) { "my_token" }
  let(:service) do
    AhaServices::Trello.new "server_url" => base_url
  end

  let(:card_id) { "dummy_trello_card_id" }

  def trello_url(path)
    "#{base_url}/#{path}?key=#{oauth_key}&token=#{oauth_token}"
  end

  before do
    service.stub(:oauth_key).and_return(oauth_key)
    service.stub(:oauth_token).and_return(oauth_token)
    stub_aha_api_posts
  end

  it "can receive new features" do
    service.stub(:payload)
      .and_return(Hashie::Mash.new(json_fixture("create_feature_event.json")))
    stub_request(:post, trello_url("cards"))
      .to_return(status: 201, body: '{"id": "12345"}')
    service.receive(:create_feature)
  end

  it "can update existing features" do
    service.stub(:payload)
      .and_return(Hashie::Mash.new(json_fixture("update_feature_event.json")))
    stub_request(:get, trello_url("cards/#{card_id}"))
      .to_return(status: 200, body: "{\"id\": \"#{card_id}\"}")
    stub_request(:put, trello_url("cards/#{card_id}"))
      .to_return(status: 200)
    service.receive(:update_feature)
  end
end
