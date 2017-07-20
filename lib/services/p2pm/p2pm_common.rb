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

    
    select :table, id: "The tables in Process Maker.",
      collection: ->(meta_data, data) {
      return [] if meta_data.nil? or meta_data.tables.nil?
      meta_data.tables.collect do |id, table|
        if table.name == "PMT_TFS_DATA"
          [table.name, table.id]
        end
      end
    }
    
    string :security_token, description: "Retrieved Security Token", collection: ->(meta_data, data) {meta_data.security_token}

    def receive_installed
      meta_data.tables = project_resource.all
      #workitemtype_resource.determine_possible_workflows(meta_data)
      #classification_nodes_resource.get_areas_for_all_projects(meta_data)
    end

    def receive_create_feature
      created_workitem = feature_mapping_resource.create data.table, payload.feature
    end

    def receive_update_feature
      #workitem_id = payload.feature.integration_fields.detect{|field| field.name == "id"}.value rescue nil
      #unless workitem_id.nil?
        #feature_mapping_resource.update workitem_id, payload.feature, data.table
      #end
      created_workitem = feature_mapping_resource.create data.table, payload.feature
    end 

  end

 protected
   
  def project_resource
    @project_resource ||= P2PMProjectResource.new(self)
  end

  def workitem_resource
    @workitem_resource ||= P2PMWorkItemResource.new(self)
  end

  def feature_mapping_resource
    @feature_mapping_resource ||= P2PMFeatureMappingResource.new(self)
  end

end
