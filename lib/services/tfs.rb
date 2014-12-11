class AhaServices::TFS < AhaService
  caption "Send features and requirements to Microsoft Team Foundation Server"

  string :account_name, description: "The name of your Visual Studio subdomain."
  string :user_name, description: "The name of the user used to access Visual Studio Online."
  password :user_password, description: "The password of the user used to access Visual Studio Online."

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

  select :requirement_mapping, collection: -> (meta_data, data) {
    project = meta_data.projects[data.project] rescue nil
    return [] unless project
    meta_data.workflow_sets[project.workflow].requirement_mappings.collect do |name, wit|
      [name, name]
    end
  }

  internal :requirement_status_mapping

  callback_url description: "This url will be used to receive updates from TFS."

  def receive_installed
    meta_data.projects = project_resource.all
    workitemtype_resource.determin_possible_workflows(meta_data)
    classification_nodes_resource.get_areas_for_all_projects(meta_data)
    setup_subscriptions
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
      url = payload.webhook.resource._links.parent.href
      workitem = workitem_resource.by_url url
      results = api.search_integration_fields(data.integration_id, "id", workitem.id)['records']
      return if results.length != 1
      if results[0].feature then
        feature_resource.update_aha_feature results[0].feature, workitem
      elsif results[0].requirement then
        requirement_mapping_resource.update_aha_requirement results[0].requirement, workitem
      end
    rescue AhaApi::NotFound
      return # Ignore features that we don't have Aha! features for.
    end
  end

protected
  def setup_subscriptions
    subscriptions = subscriptions_resource.all
    ok_project_ids = subscriptions.select{|s| s.consumerInputs.url == data.callback_url }.map{|s| s.publisherInputs.projectId }
    todo_projects = meta_data.projects.reject{|id, p| ok_project_ids.include?(id) }
    todo_projects.each do |id, p|
      subscriptions_resource.create id, data.callback_url
    end
  end
  
  def project_resource
    @project_resource ||= TFSProjectResource.new(self)
  end

  def workitem_resource
    @workitem_resource ||= TFSWorkItemResource.new(self)
  end

  def subscriptions_resource
    @subscriptions_resource ||= TFSSubscriptionsResource.new(self)
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
