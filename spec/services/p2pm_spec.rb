require "spec_helper"

# The following operations are supported:
#
# * Installing the service
# * Creating a Process Maker record
# * Uploading attachments
#
describe AhaServices::P2PM do
  def get_oauth
     let(:p2pm_oauth_url) { "http://ddevwf1/workflow/oauth2/token" }

     stub_request(:post, )
  end
  def stub_requests

    
    let(:p2pm_api_url) { "http://ddevwf1/api/1.0/workflow"}
    # OAuth

    # Tables
    stub_request(:get, /pmtable/).
      to_return(status: 200, body: raw_fixture("p2pm/p2pm_get_tables.json"))

  end

  #before do
    # TODO - Copied these credentials from VSO. Validate that they're correct for TFS.
  #  @account_name = "pwaller"
  #  @password = "BaseBall24"
  #end

  it "can be installed" do
    get_oauth
    stub_requests

    service = AhaServices::P2PM.new(
      { account_name: @account_name, passwod: @password },
      nil,
      {}
    )

    service.receive(:installed)
  end
end
