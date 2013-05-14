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
  
end