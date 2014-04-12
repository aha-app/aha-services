require "spec_helper"

describe AhaServices::Trello do
  let(:base_url) { "https://api.trello.com/1/" }
  let(:key) { "my_key" }
  let(:secret) { "my_secret" }
  let(:auth) { "?key=#{key}&secret=#{secret}" }
  let(:service) do
    AhaServices::Trello.new 'server_url' => base_url,
                            'key' => key, 'secret' => secret
  end

end
