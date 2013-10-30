require 'spec_helper'

describe AhaServices::JiraConnect do
  context "can be installed" do
    
    it "handles installed event" do
      service = AhaServices::JiraConnect.new(:installed,
        {'server_url' => 'http://foo.com/a', 'api_version' => 'a'},
        nil)
      service.receive
      service.meta_data.projects[0]["key"].should == "APPJ"
      service.meta_data.projects[0].issue_types[0].name.should == "Bug"     
      service.meta_data.projects[0].issue_types[0].statuses[0].name.should == "Open"     
    end
  end
end