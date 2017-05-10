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

    select :project, description: "The tables in Process Maker.",
      collection: ->(meta_data, data) {
      return [] if meta_data.nil? or meta_data.projects.nil?
      meta_data.tables.collect do |id, name|
        [table.name, table.id]
      end
    }

    def receive_installed
      meta_data.tables = project_resource.all
      #workitemtype_resource.determine_possible_workflows(meta_data)
      #classification_nodes_resource.get_areas_for_all_projects(meta_data)
    end
  end

 protected
   
  def project_resource
    @project_resource ||= P2PMProjectResource.new(self)
  end

end