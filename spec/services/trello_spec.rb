require "spec_helper"
require "json"

describe AhaServices::Trello do
  let(:base_url) { "https://api.trello.com/1" }
  let(:oauth_key) { "my_key" }
  let(:oauth_token) { "my_token" }
  let(:service) do
    AhaServices::Trello.new "server_url" => base_url
  end

  let(:card_id) { "dummy_trello_card_id" }
  let(:checklist_id) { "dummy_trello_checklist_id" }
  let(:checklist_item_id) { "dummy_trello_checklist_item_id" }

  def trello_url(path)
    "#{base_url}/#{path}?key=#{oauth_key}&token=#{oauth_token}"
  end

  before do
    service.data.stub(:oauth_key).and_return(oauth_key)
    service.data.stub(:oauth_token).and_return(oauth_token)
    stub_aha_api_posts
  end

  it "can receive new features" do
    service.stub(:payload)
      .and_return(Hashie::Mash.new(json_fixture("create_feature_event.json")))
    stub_request(:post, trello_url("cards"))
      .to_return(status: 201, body: {id: card_id}.to_json)
    stub_request(:post, trello_url("cards/#{card_id}/actions/comments"))
      .to_return(status: 201)
    stub_request(:get, trello_url("cards/#{card_id}/checklists"))
      .to_return(status: 200, body: "[]")
    stub_request(:post, trello_url("checklists"))
      .to_return(status: 201, body: {id: checklist_id}.to_json)
    stub_request(:post, trello_url("checklists/#{checklist_id}/checkItems"))
      .to_return(status: 201, body: {id: checklist_item_id}.to_json)
    stub_request(:get, trello_url("blah"))
      .to_return(status: 200)
    service.receive(:create_feature)
  end

  it "can update existing features" do
    service.stub(:payload)
      .and_return(Hashie::Mash.new(json_fixture("update_feature_event.json")))
    stub_request(:get, trello_url("cards/#{card_id}"))
      .to_return(status: 200, body: {id: card_id}.to_json)
    stub_request(:put, trello_url("cards/#{card_id}"))
      .to_return(status: 200)
    stub_request(:get, trello_url("checklists/#{checklist_id}/checkitems/#{checklist_item_id}"))
      .to_return(status: 200, body: {id: checklist_item_id}.to_json)
    stub_request(:put, trello_url("cards/#{card_id}/checklist/#{checklist_id}/checkItem/#{checklist_item_id}"))
      .to_return(status: 200)
    service.receive(:update_feature)
  end
end
