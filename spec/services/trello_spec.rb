require "spec_helper"
require "json"

describe AhaServices::Trello do
  let(:aha_api_url) { "https://a.aha.io/api/v1" }
  let(:base_url) { "https://api.trello.com/1" }
  let(:oauth_key) { "my_key" }
  let(:oauth_token) { "my_token" }
  let(:service) do
    AhaServices::Trello.new "server_url" => base_url, "integration_id" => 111
  end

  let(:card_id) { "dummy_trello_card_id" }
  let(:checklist_id) { "dummy_trello_checklist_id" }
  let(:checklist_item_id) { "dummy_trello_checklist_item_id" }
  let(:callback_url) { "http://some_url.com"}
  let(:feature_statuses) do
    { "list_id1" => "status1", "list_id2" => "under_consideration" }
  end

  def trello_url(path)
    "#{base_url}/#{path}?key=#{oauth_key}&token=#{oauth_token}"
  end

  before do
    service.data.stub(:create_features_at).and_return("bottom")
    service.data.stub(:list_for_new_features).and_return("list_id1")
    service.data.stub(:oauth_key).and_return(oauth_key)
    service.data.stub(:oauth_token).and_return(oauth_token)
    service.data.stub(:callback_url).and_return(callback_url)
    service.data.stub(:feature_statuses).and_return(feature_statuses)
  end

  it "can receive new features" do
    new_feature_event = Hashie::Mash.new(json_fixture("create_feature_event.json"))
    service.stub(:payload).and_return(new_feature_event)
    new_feature = new_feature_event.feature

    create_card = stub_request(:post, trello_url("cards"))
      .to_return(status: 200, body: {id: card_id}.to_json)
    create_webhook = stub_request(:post, trello_url("webhooks"))
      .with(body: {
        callbackURL: "#{callback_url}?feature=PROD-2",
        idModel: card_id
      }.to_json)
      .to_return(status: 200)
    integrate_feature_with_card = stub_request(:post, "#{aha_api_url}/features/#{new_feature.reference_num}/integrations/111/fields")
      .with(body: {
        integration_fields: [
          {
            name: "id",
            value: card_id
          },
          {
            name: "url",
            value: "https://trello.com/c/#{card_id}"
          }
        ]
      })
      .to_return(status: 200)
    create_comment = stub_request(:post, trello_url("cards/#{card_id}/actions/comments"))
      .with(body: { text: "Created from Aha! #{new_feature.url}" }.to_json)
      .to_return(status: 200)
    get_checklists = stub_request(:get, trello_url("cards/#{card_id}/checklists"))
      .to_return(status: 200, body: "[]")
    create_checklist = stub_request(:post, trello_url("checklists"))
      .with(body: {
        idCard: card_id,
        name: "Requirements"
      }.to_json)
      .to_return(status: 200, body: {id: checklist_id}.to_json)
    create_checklist_item = stub_request(:post, trello_url("checklists/#{checklist_id}/checkItems"))
      .with(body: {
        idChecklist: checklist_id,
        name: "Requirement 1. First requirement\n\n"
      }.to_json)
      .to_return(status: 200, body: {id: checklist_item_id}.to_json)
    integrate_requirement_with_checklist_item = stub_request(:post, "#{aha_api_url}/requirements/#{new_feature.requirements[0].reference_num}/integrations/111/fields")
    .with(body: {
      integration_fields: [
        {
          name: "id",
          value: checklist_item_id
        },
        {
          name: "checklist_id",
          value: checklist_id
        }
      ]
    })
    get_attachments = stub_request(:get, trello_url("cards/#{card_id}/attachments"))
      .to_return(status: 200, body: "[]")
    create_attachment = stub_request(:post, trello_url("cards/#{card_id}/attachments"))
      .to_return(status: 200)
      
    # Attachments
    stub_request(:get, "https://attachments.s3.amazonaws.com/attachments/80641a3d3141ce853ea8642bb6324534fafef5b3/original.png?1370458143").
      to_return(:status => 200, :body => "", :headers => {})
    stub_request(:get, "https://attachments.s3.amazonaws.com/attachments/6fad2068e2aa0e031643d289367263d3721c8683/original.png?1370458145").
      to_return(:status => 200, :body => "", :headers => {})
    stub_request(:get, "https://attachments.s3.amazonaws.com/attachments/6cce987f6283d15c080e53bba15b1072a7ab5b07/original.png?1370457053").
      to_return(:status => 200, :body => "", :headers => {})
    stub_request(:get, "https://attachments.s3.amazonaws.com/attachments/d1cb788065a70dad7ba481c973e19dcd379eb202/original.png?1370457055").
      to_return(:status => 200, :body => "", :headers => {})
          
    service.receive(:create_feature)

    expect(create_card).to have_been_requested.once
    expect(integrate_feature_with_card).to have_been_requested.once
    expect(create_comment).to have_been_requested.once
    expect(get_checklists).to have_been_requested.once
    expect(create_checklist).to have_been_requested.once
    expect(create_checklist_item).to have_been_requested.once
    expect(integrate_requirement_with_checklist_item).to have_been_requested.once
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

    create_card = stub_request(:post, "https://api.trello.com/1/cards?key=my_key&token=my_token")
      .to_return(:status => 200, :body => "", :headers => {})
    stub_request(:post, "https://a.aha.io/api/v1/features/PROD-2/integrations/111/fields")
      .to_return(:status => 200)
    stub_request(:post, "https://api.trello.com/1/cards//actions/comments?key=my_key&token=my_token")
      .to_return(:status => 200)
    stub_request(:post, "https://api.trello.com/1/cards//actions/comments?key=my_key&token=my_token")
      .to_return(:status => 200)
    get_card = stub_request(:get, "https://api.trello.com/1/cards//checklists?key=my_key&token=my_token")
      .to_return(:status => 200)
    save_card = stub_request(:post, "https://api.trello.com/1/checklists?key=my_key&token=my_token")
      .to_return(:status => 200)
    save_checklist_item = stub_request(:post, "https://api.trello.com/1/checklists//checkItems?key=my_key&token=my_token")
      .to_return(:status => 200)
    stub_request(:post, "https://a.aha.io/api/v1/requirements/PROD-2-1/integrations/111/fields")
      .to_return(:status => 200)
    get_attachments = stub_request(:get, "https://api.trello.com/1/cards//attachments?key=my_key&token=my_token")
      .to_return(:status => 200)
    create_attachments = stub_request(:post, "https://api.trello.com/1/cards//attachments?key=my_key&token=my_token")
      .to_return(:status => 200)

    # Attachments
    stub_request(:get, "https://attachments.s3.amazonaws.com/attachments/80641a3d3141ce853ea8642bb6324534fafef5b3/original.png?1370458143").
      to_return(:status => 200, :body => "", :headers => {})
    stub_request(:get, "https://attachments.s3.amazonaws.com/attachments/6fad2068e2aa0e031643d289367263d3721c8683/original.png?1370458145").
      to_return(:status => 200, :body => "", :headers => {})
    stub_request(:get, "https://attachments.s3.amazonaws.com/attachments/6cce987f6283d15c080e53bba15b1072a7ab5b07/original.png?1370457053").
      to_return(:status => 200, :body => "", :headers => {})
    stub_request(:get, "https://attachments.s3.amazonaws.com/attachments/d1cb788065a70dad7ba481c973e19dcd379eb202/original.png?1370457055").
      to_return(:status => 200, :body => "", :headers => {})

    service.receive(:update_feature)

    expect(get_card).to have_been_requested.once
    expect(save_card).to have_been_requested.once
    # Checking if the checklist item integrated with the requirement exists
    expect(save_checklist_item).to have_been_requested.once
    expect(get_attachments).to have_been_requested.twice
    # We are expecting only three of four attachments to be uploaded
    # since one of them is already attached to the card
    expect(create_attachments).to have_been_requested.times(4)
  end

  it "escapes file names properly" do
    # this filename is the result of aha doing all of its escaping
    expect(service.trelloize_filename("Screen Shot 2017-06-26 at 9.51.26 AM !______*() -___ __ __ __ _'\"___.__ ī ™.png")).
      to eq("Screen_Shot_2017-06-26_at_9.51.26_AM_!_______()_-___________________.___i%CC%84_%E2%84%A2.png")
  end
end
