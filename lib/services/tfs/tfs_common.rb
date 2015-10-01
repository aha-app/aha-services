module TfsCommon
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

    select :project, description: "The project you want to create new workitems in.",
      collection: ->(meta_data, data) {
      return [] if meta_data.nil? or meta_data.projects.nil?
      meta_data.projects.collect do |id, project|
        [project.name, project.id]
      end
    }

    select :area, description: "The area of the project you want to create new workitems in.", collection: ->(meta_data, data) {
      return [] if meta_data.nil? or meta_data.projects.nil? or data.project.nil?
      project = meta_data.projects[data.project]
      return [] if project.nil? or project.areas.nil?
      project.areas.collect do |area|
        [area, area]
      end
    }

    select :feature_mapping, collection: -> (meta_data, data) {
      project = meta_data.projects[data.project] rescue nil
      return [] unless project
      meta_data.workflow_sets[project.workflow].feature_mappings.collect do |name, wit|
        [name, name]
      end
    }

    internal :feature_status_mapping
    internal :feature_default_fields
  
    select :requirement_mapping, collection: -> (meta_data, data) {
      project = meta_data.projects[data.project] rescue nil
      return [] unless project
      meta_data.workflow_sets[project.workflow].feature_mappings.collect do |name, wit|
        [name, name]
      end
    }

    internal :requirement_status_mapping
    internal :requirement_default_fields

    callback_url description: "This url will be used to receive updates from TFS."
  end
  
  def receive_installed
    meta_data.projects = project_resource.all
    workitemtype_resource.determine_possible_workflows(meta_data)
    classification_nodes_resource.get_areas_for_all_projects(meta_data)
  end

  def receive_create_feature
    created_workitem = feature_mapping_resource.create data.project, payload.feature
  end

  def receive_update_feature
    workitem_id = payload.feature.integration_fields.detect{|field| field.name == "id"}.value rescue nil
    unless workitem_id.nil?
      feature_mapping_resource.update workitem_id, payload.feature
    end
  end

  def receive_webhook
    begin
      return unless payload.webhook && payload.webhook.resource && payload.webhook.resource._links && payload.webhook.resource._links.parent
      url = payload.webhook.resource._links.parent.href
      return if test_webook(url)
      
      workitem = workitem_resource.by_url(remap_url(url))
      results = api.search_integration_fields(data.integration_id, "id", workitem.id)['records']
      return if results.length != 1
      if results[0].feature then
        feature_mapping_resource.update_aha_feature results[0].feature, workitem
      elsif results[0].requirement then
        requirement_mapping_resource.update_aha_requirement results[0].requirement, workitem
      end
    rescue AhaApi::NotFound
      return # Ignore features that we don't have Aha! features for.
    end
  end

protected
  
  # Check if this is a test servicehook, in which case we ignore it.
  def test_workhook(url)
    logger.info("Received test webhook")
    URI(url).host == "fabrikam-fiber-inc.visualstudio.com"
  end

  # On premise TFS servers frequently use DNS names that are only valid inside
  # the LAN. We need to remap to make the address valid for external use. 
  def remap_url(original_url)
    return original_url if self.class.service_name == "tfs"
    
    server_uri = URI(data.server_url)
    
    uri = URI(original_url)
    uri.scheme = server_uri.scheme
    uri.host = server_uri.host
    uri.port = server_uri.port
    uri.to_s
  end
  
  def project_resource
    @project_resource ||= TFSProjectResource.new(self)
  end

  def workitem_resource
    @workitem_resource ||= TFSWorkItemResource.new(self)
  end

  def feature_mapping_resource
    @feature_mapping_resource ||= TFSFeatureMappingResource.new(self)
  end

  def requirement_mapping_resource
    @requirement_mapping_resource ||= TFSRequirementMappingResource.new(self)
  end

  def workitemtype_resource
    @workitemtype_resource ||= TFSWorkitemtypeResource.new(self)
  end

  def classification_nodes_resource
    @classification_nodes_resource ||= TFSClassificationNodesResource.new(self)
  end
end
