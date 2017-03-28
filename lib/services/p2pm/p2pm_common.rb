module P2PMCommon
      include Schema
  extend Schema::ClassMethods
  
  def self.included(klass)
    # Hook into the class's schema so that all items are combined.
    @klass_schema = klass.schema()
    def self.schema
      @klass_schema
    end

    #
    # Common schema items.
    #
    
    install_button
  end
protected
  
  # Check if this is a test servicehook, in which case we ignore it.
  def test_webhook(url)
    URI(url).host == "fabrikam-fiber-inc.visualstudio.com"
  end

  # On premise TFS servers frequently use DNS names that are only valid inside
  # the LAN. We need to remap to make the address valid for external use. 
  def remap_url(original_url)
    return original_url if self.class.service_name == "p2_pm"
    
    server_uri = URI(data.server_url)
    
    uri = URI(original_url)
    uri.scheme = server_uri.scheme
    uri.host = server_uri.host
    uri.port = server_uri.port
    uri.to_s
  end
  
  def project_resource
    @project_resource ||= P2PMProjectResource.new(self)
  end

  def workitemtype_resource
    @workitemtype_resource ||= P2PMWorkitemtypeResource.new(self)
  end

  def feature_mapping_resource
    @feature_mapping_resource ||= P2PMFeatureMappingResource.new(self)
  end


end
