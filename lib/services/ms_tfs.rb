require 'erb'

class AhaServices::MSTFS < AhaService
  caption "Send features to Microsoft Team Foundation Server"

  string :account_name, description: "The name of your Visual Studio subdomain."
  string :user_name, description: "The name of the user used to access Visual Studio Online."
  string :user_password, description: "The password of the user used to access Visual Studio Online."

  install_button

  select :project, description: "The project you want to create new features in.",
    collection: ->(meta_data, data) {
    return [] if meta_data.nil? or meta_data.projects.nil?
    meta_data.projects.collect do |project|
      [project.name, project.id]
    end
  }

  select :requirement_mapping, collection: [ [ "User Story", "User Story" ], [ "Requirement", "Requirement" ], [ "Product Backlog Item", "Product Backlog Item" ] ]

  callback_url description: "This url will be used to receive updates from TFS."

  def receive_installed
    meta_data.projects = project_resource.all
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
    # no-op
    # TODO: implement two way sync
    begin
      url = payload.webhook.resource._links.parent.href
      workitem = workitem_resource.by_url url
      results = api.search_integration_fields(data.integration_id, "id", workitem.id)['records']
      return if results.length != 1
      return unless results[0].feature
      feature_resource.update_aha_feature results[0].feature, workitem
    rescue AhaApi::NotFound
      return # Ignore features that we don't have Aha! features for.
    end
  end

protected
  def project_resource
    @project_resource ||= MSTFSProjectResource.new(self)
  end

  def workitem_resource
    @workitem_resource ||= MSTFSWorkItemResource.new(self)
  end

  def subscriptions_resource
    @subscriptions_resource ||= MSTFSSubscriptionsResource.new(self)
  end

  def feature_resource
    @feature_resource ||= MSTFSFeatureResource.new(self)
  end
end
