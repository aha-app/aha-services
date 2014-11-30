require 'erb'

class AhaServices::TFS < AhaService
  caption "Send features to Microsoft Team Foundation Server"

  string :account_name, description: "The name of your Visual Studio subdomain."
  string :user_name, description: "The name of the user used to access Visual Studio Online."
  password :user_password, description: "The password of the user used to access Visual Studio Online."

  install_button

  select :project, description: "The project you want to create new features in.",
    collection: ->(meta_data, data) {
    return [] if meta_data.nil? or meta_data.projects.nil?
    meta_data.projects.collect do |project|
      [project.name, project.id]
    end
  }

  select :requirement_mapping, collection: -> (meta_data, data) {
    return [] if meta_data.nil? or meta_data.projects.nil? or data.project.nil?
    project = meta_data.projects.find{|p| p.id == data.project}
    meta_data.workflow_sets[project.workflow].collect do |wit|
      [wit.name, wit.name]
    end
  }

  callback_url description: "This url will be used to receive updates from TFS."

  def receive_installed
    meta_data.projects = project_resource.all
    workitemtype_resource.determin_possible_workflows(meta_data)
  end

  def receive_create_feature
    created_feature = feature_resource.create data.project, payload.feature
  end

  def receive_update_feature
    tfs_feature_id = payload.feature.integration_fields.detect{|field| field.name == "id"}.value rescue nil
    unless tfs_feature_id.nil?
      feature_resource.update tfs_feature_id, payload.feature
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
  def project_resource
    @project_resource ||= TFSProjectResource.new(self)
  end

  def workitem_resource
    @workitem_resource ||= TFSWorkItemResource.new(self)
  end

  def subscriptions_resource
    @subscriptions_resource ||= TFSSubscriptionsResource.new(self)
  end

  def feature_resource
    @feature_resource ||= TFSFeatureResource.new(self)
  end

  def requirement_mapping_resource
    @requirement_mapping_resource ||= TFSRequirementMappingResource.new(self)
  end

  def workitemtype_resource
    @workitemtype_resource ||= TFSWorkitemtypeResource.new(self)
  end
end
