require 'spec_helper'

describe AhaServices::Bugzilla do
  let(:server_url) { "https://landfill.bugzilla.org/bugzilla-tip" }
  let(:api_key) { "CNtLoMy5N167hq56cCJH5ixDOxmGrHYuZSmZA0H4" }

  let(:product) { "4" }
  let(:component) { "14" }

  let(:aha_api_url) { "https://a.aha.io/api/v1" }
  let(:integration_id) { "30071774" }

  let :service do
    AhaServices::Bugzilla.new({
      'server_url' => server_url,
      'api_key' => api_key,
      'product' => product,
      'component' => component,
      'integration_id' => integration_id,
    }, nil, {})
  end


  before do
    stub_download_feature_attachments
    allow(IPSocket).to receive(:getaddress).and_return("1.1.1.1")
  end

  context "when installing" do
    before do
      @stub_get_product_enterable = stub_request(:get, "#{server_url}/rest/product_enterable?api_key=#{api_key}").
                                    to_return(:status => 200, :body => raw_fixture("bugzilla/product_enterable.json"))
      @stub_get_products_components = stub_request(:get, "#{server_url}/rest/product?api_key=#{api_key}&ids=2&ids=3&ids=19&ids=1&ids=4&include_fields=id,name,components.id,components.name").
                                      to_return(:status => 200, :body => raw_fixture("bugzilla/products.json"))
      @stub_get_bug_field = stub_request(:get, "#{server_url}/rest/field/bug?api_key=#{api_key}").
                            to_return(:status => 200, :body => raw_fixture("bugzilla/fields.json"))
    end

    it "fetches products and components" do
      service.receive(:installed)

      expect(service.meta_data[:products].size).to be 5
    end
  end

  describe "recieving new feature" do
    let(:service) do
        AhaServices::Bugzilla.new({
          'server_url' => server_url,
          'api_key' => api_key,
          'product' => product,
          'component' => component,
          'integration_id' => integration_id,
        }, json_fixture('create_feature_event.json'), {})
    end

    before do
      products = Hashie::Mash.new(json_fixture("bugzilla/products.json")).products
      service.meta_data.stub(:products).and_return(products)

      @stub_create_bug = stub_request(:post, "#{server_url}/rest/bug?api_key=#{api_key}").
                         to_return(:status => 200, :body => raw_fixture("bugzilla/new_bug.json"))
      @stub_update_bug = stub_request(:put, "#{server_url}/rest/bug/123456?api_key=#{api_key}").
                         to_return(:status => 200)
      @stub_create_attachment = stub_request(:post, "#{server_url}/rest/bug/123456/attachment?api_key=#{api_key}").
                                to_return(:status => 200)
      @integrate_feature = stub_request(:post, "#{aha_api_url}/features/PROD-2/integrations/#{integration_id}/fields")
                           .to_return(:status => 201, :headers => {}, :body => "")
      @integrate_requirement = stub_request(:post, "#{aha_api_url}/requirements/PROD-2-1/integrations/#{integration_id}/fields")
    end

    it "creates new bugs" do
      service.receive(:create_feature)

      expect(@stub_create_bug).to have_been_requested.twice
      expect(@stub_update_bug).to have_been_requested.once
      expect(@stub_create_attachment).to have_been_requested.times 4
    end
  end

  describe "recieving updated feature" do
    let(:service) do
        AhaServices::Bugzilla.new({
          'server_url' => server_url,
          'api_key' => api_key,
          'product' => product,
          'component' => component,
          'integration_id' => integration_id,
        }, json_fixture('update_feature_event.json'), {})
    end

    before do
      products = Hashie::Mash.new(json_fixture("bugzilla/products.json")).products
      service.meta_data.stub(:products).and_return(products)

      @stub_update_bug = stub_request(:put, "#{server_url}/rest/bug/123456?api_key=#{api_key}").
                         to_return(:status => 200)
      @stub_get_attachments = stub_request(:get, "#{server_url}/rest/bug/123456/attachment?api_key=#{api_key}&exclude_fields=data").
                              to_return(:status => 200, :body => raw_fixture("bugzilla/attachments.json"))
      @integrate_feature = stub_request(:post, "#{aha_api_url}/features/PROD-2/integrations/#{integration_id}/fields")
                           .to_return(:status => 201, :headers => {}, :body => "")
      @integrate_requirement = stub_request(:post, "#{aha_api_url}/requirements/PROD-2-1/integrations/#{integration_id}/fields")
    end

    it "creates new bugs" do
      service.receive(:update_feature)

      expect(@stub_update_bug).to have_been_requested.times 2
      expect(@stub_get_attachments).to have_been_requested.times 2
    end
  end
end
