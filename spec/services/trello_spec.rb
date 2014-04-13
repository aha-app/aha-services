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
    service.data.stub(:create_features_at).and_return("bottom")
    service.data.stub(:oauth_key).and_return(oauth_key)
    service.data.stub(:oauth_token).and_return(oauth_token)
    stub_aha_api_posts
  end

  it "can receive new features" do
    new_feature_event = Hashie::Mash.new(json_fixture("create_feature_event.json"))
    service.stub(:payload).and_return(new_feature_event)
    new_feature = new_feature_event.feature

    create_card = stub_request(:post, trello_url("cards"))
      .with(body: {
        name: new_feature.name,
        desc: "",
        pos: "bottom",
        due: "null",
        idList: "dummy_list_id"
      }.to_json)
      .to_return(status: 201, body: {id: card_id}.to_json)
    create_comment = stub_request(:post, trello_url("cards/#{card_id}/actions/comments"))
      .with(body: { text: "Created from Aha! #{new_feature.url}" }.to_json)
      .to_return(status: 201)
    get_checklists = stub_request(:get, trello_url("cards/#{card_id}/checklists"))
      .to_return(status: 200, body: "[]")
    create_checklist = stub_request(:post, trello_url("checklists"))
      .with(body: {
        idCard: card_id,
        name: "Requirements"
      }.to_json)
      .to_return(status: 201, body: {id: checklist_id}.to_json)
    create_checklist_item = stub_request(:post, trello_url("checklists/#{checklist_id}/checkItems"))
      .with(body: {
        idChecklist: checklist_id,
        name: "Requirement 1. First requirement\n\n"
      }.to_json)
      .to_return(status: 201, body: {id: checklist_item_id}.to_json)
    get_attachments = stub_request(:get, trello_url("cards/#{card_id}/attachments"))
      .to_return(status: 200, body: "[]")
    create_attachment = stub_request(:post, trello_url("cards/#{card_id}/attachments"))
      .to_return(status: 201)

    service.receive(:create_feature)

    expect(create_card).to have_been_requested.once
    expect(create_comment).to have_been_requested.once
    expect(get_checklists).to have_been_requested.once
    expect(create_checklist).to have_been_requested.once
    expect(create_checklist_item).to have_been_requested.once
    # Expecting to issue get_attachments request twice:
    # first time when handling feature attachments,
    # second time when handling requirement attachments
    expect(get_attachments).to have_been_requested.twice
    # One request for each feature and requirement attachment
    expect(create_attachment).to have_been_requested.times(4)
  end

  it "can update existing features" do
    update_feature_event = Hashie::Mash.new(json_fixture("update_feature_event.json"))
    service.stub(:payload).and_return(update_feature_event)
    updated_feature = update_feature_event.feature

    get_card = stub_request(:get, trello_url("cards/#{card_id}"))
      .to_return(status: 200, body: {id: card_id}.to_json)
    save_card = stub_request(:put, trello_url("cards/#{card_id}"))
      .with(body: {
        name: updated_feature.name,
        desc: "",
        idList: "dummy_list_id"
      }.to_json)
      .to_return(status: 200)
    get_checklist_item = stub_request(:get, trello_url("checklists/#{checklist_id}/checkitems/#{checklist_item_id}"))
      .to_return(status: 200, body: {id: checklist_item_id}.to_json)
    save_checklist_item = stub_request(:put, trello_url("cards/#{card_id}/checklist/#{checklist_id}/checkItem/#{checklist_item_id}"))
      .with(body: {
        idChecklistCurrent: checklist_id,
        idCheckItem: checklist_item_id,
        name: "Requirement 1. First requirement  \n, changed\n\n"
      }.to_json)
      .to_return(status: 200)
    get_attachments = stub_request(:get, trello_url("cards/#{card_id}/attachments"))
      .to_return(status: 200, body: [{url: "Finland.png", bytes: 28265}].to_json)
    create_attachments = stub_request(:post, trello_url("cards/#{card_id}/attachments"))
      .to_return(status: 201)

    service.receive(:update_feature)

    expect(get_card).to have_been_requested.once
    expect(save_card).to have_been_requested.once
    # Checking if the checklist item integrated with the requirement exists
    expect(get_checklist_item).to have_been_requested.once
    expect(save_checklist_item).to have_been_requested.once
    expect(get_attachments).to have_been_requested.twice
    # We are expecting only three of four attachments to be uploaded
    # since one of them is already attached to the card
    expect(create_attachments).to have_been_requested.times(3)
  end
end
