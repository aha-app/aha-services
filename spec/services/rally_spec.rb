require 'spec_helper'

describe AhaServices::Rally do
  let(:api_url) { "https://rally1.rallydev.com/slm/webservice/v2.0" }
  
  let(:project) { 22098603406 }

  context "receiving installed" do
    let(:service) {
      AhaServices::Rally.new({:project => project }, nil, {})
    }

    it "fetches all projects" do
      get_projects = stub_request(:get, "https://rally1.rallydev.com/slm/webservice/v2.0/project?fetch=true")
                     .to_return(:status => 200, :headers => {}, :body => raw_fixture("rally/get_projects.json"))
      service.receive(:installed)
      expect(get_projects).to have_been_requested
      expect(service.meta_data.projects.size).to be(2)
    end
  end

  context "receiving new release" do
    let(:service) {
      AhaServices::Rally.new({:project => project}, json_fixture("create_release_event.json"))
    }
  end
end
