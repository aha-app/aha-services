require 'spec_helper'

describe AhaServices::JiraConnect do
  context "can be installed" do
    
    it "handles installed event" do
      stub_request(:get, "http://foo.com/a/rest/api/2/issue/createmeta?expand=projects.issuetypes.fields&user_id=chris").
        to_return(:status => 200, :body => raw_fixture('jira/jira_createmeta.json'), :headers => {})
      stub_request(:get, "http://foo.com/a/rest/api/2/project/APPJ/statuses?user_id=chris").
        to_return(:status => 200, :body => raw_fixture('jira/jira_project_statuses.json'), :headers => {})
      stub_request(:get, "http://foo.com/a/rest/api/2/resolution?user_id=chris").
        to_return(:status => 200, :body => raw_fixture('jira/jira_resolutions.json'), :headers => {})
      stub_request(:get, "http://foo.com/a/rest/api/2/field?user_id=chris").
        to_return(:status => 200, :body => raw_fixture('jira/jira_field.json'), :headers => {})

      private_key = <<-EOF
-----BEGIN RSA PRIVATE KEY-----
MIIBOgIBAAJBAOAOI6PHOTjZ3xqG2h2yr231bEj+Kmg89xRkJswTJg26bDudxdob
CJWpRUDxnU4kCNq97QegiWxHtyBr4ZXrV00CAwEAAQJAdcQYyYn6sr4ZvWiqFrgH
64T3QLqPcbCxsf8eQV/DPa0GO2GEjcYyk37e/7MY1lDFSbYQSDqSPj036bcqUaps
JQIhAPbF4heJjJpqdce+07H5q6AyEq4mHIMQw2hhizhJ9EG/AiEA6G7NG9dLiPKN
p84oSjjshlZnnf1e7+Z4sNKE3Vec0fMCIQCbgOMSVfkmLUP/FP8tvdkq36Lp3tZE
uUGJ+z3RwLiM3QIgXDcBdyc+l5Grs8St5WyaIl4Lc/n+/WzRu016WxqUZBMCIFZd
AP8se1NO6bEg8WfYO7jYic+ppDHLssu0a5xvo1z8
-----END RSA PRIVATE KEY-----
EOF
      service = AhaServices::JiraConnect.new(
        {'server_url' => 'http://foo.com/a', 'api_version' => 'a', 
          'consumer_key' => 'io.aha.connect', 'consumer_secret' => private_key, 'user_id' => 'chris'},
        nil)
      service.receive(:installed)
      service.meta_data.projects[0]["key"].should == "APPJ"
      service.meta_data.projects[0].issue_types[0].name.should == "Bug"     
      service.meta_data.projects[0].issue_types[0].statuses[0].name.should == "Open"     
    end
  end
end