require 'spec_helper'

describe AhaService do
  
  context "has schema" do
    class SchemaService < AhaService
      title "Custom!"
      service_name "custom"

      string :abc
      password :def
      boolean :ghi

      white_list :abc, :ghi
    end
    
    it "can set custom title" do
      SchemaService.title.should == "Custom!"
      SchemaService.service_name.should == "custom"
    end
    
    it "has configuration attributes" do
      SchemaService.schema.should == [
          [:string, :abc, {}],
          [:password, :def, {}],
          [:boolean, :ghi, {}]
        ]
    end

    it "has whitelisted attributes" do
      SchemaService.white_listed.should == [:abc, :ghi]
    end
    
  end
  
  context "networking" do
    let (:service) { SchemaService.new }
    
    it "rejects local addresses" do
      expect { service.verify_url("http://127.0.0.1/") }.to raise_error(AhaService::InvalidUrlError)
      expect { service.verify_url("http://lvh.me/") }.to raise_error(AhaService::InvalidUrlError)
      expect { service.verify_url("http://10.0.1.2/") }.to raise_error(AhaService::InvalidUrlError)
      expect { service.verify_url("http://192.168.2.1/") }.to raise_error(AhaService::InvalidUrlError)
    end

    it "raises faraday errors as config erros" do
      allow(service).to receive(:http) do |method|
        raise Faraday::SSLError, ''
      end

      expect { service.http_method(:get, "http://google.com/") }.to raise_error(Errors::ConfigurationError)
    end
  
    it "passes faraday error messages to config erros" do
      allow(service).to receive(:http) do |method|
        raise Faraday::SSLError, 'test message'
      end

      expect { service.http_method(:get, "http://google.com/") }.to raise_error.with_message('test message')
    end

    
    it "accepts remote addresses" do
      service.verify_url("http://4.4.4.4/").should == "http://4.4.4.4/"
      service.verify_url("http://www.google.com:3000/").should == "http://www.google.com:3000/"
      service.verify_url("http://www.aha.io/").should == "http://www.aha.io/"
    end
  end
  
end