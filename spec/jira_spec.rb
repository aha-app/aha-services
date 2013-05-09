require 'spec_helper'
require 'faraday'

describe "Service::Jira" do
  before do
    @stubs = Faraday::Adapter::Test::Stubs.new
  end
  
  it "can receive new features" do
    @stubs.post "/a/rest/api/a/issue/1/transitions" do |env|
      assert_equal 'application/json', env[:request_headers]['Content-Type']
      assert_equal 'foo.com', env[:url].host
      [200, {}, '']
    end

    svc = service(Service::Jira, 
      {'server_url' => 'http://foo.com/a', 'username' => 'u', 'password' => 'p',
       'api_version' => 'a'},
      payload)
    svc.receive_create_feature
  end
end