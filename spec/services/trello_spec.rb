require "spec_helper"

describe AhaServices::Trello do
  let(:base_url) { "https://api.trello.com/1" }
  let(:key) { "my_key" }
  let(:secret) { "my_secret" }
  let(:auth) { "?key=#{key}&secret=#{secret}" }
  let(:service) do
    AhaServices::Trello.new 'server_url' => base_url,
                            'key' => key, 'secret' => secret
  end

  it "can receive new features" do
    service.stub(:payload).and_return(Hashie::Mash.new(json_fixture("create_feature_event.json")))
    stub_request(:post, "#{base_url}/cards")
      .to_return(status: 201, body: '{"id": "12345"}')
    service.should_receive(:create_or_update_trello_card)
    service.receive(:create_feature)
  end
end
