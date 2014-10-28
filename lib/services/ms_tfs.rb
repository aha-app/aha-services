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
    pp subscriptions_resource.create_maybe data.callback_url
  end

  def receive_create_feature
    feature = workitem_resource.create_feature data.project, payload.feature
    sync_requirements feature
  end

  def receive_update_feature
    # no-op
    # TODO: implement updating features
    puts "TODO: received an update"
  end

  def receive_webhook
    # no-op
    # TODO: implement two way sync
    begin
      url = payload.webhook.resource._links.parent.href
      workitem = workitem_resource.by_url url
      results = api.search_integration_fields(data.integration_id, "id", workitem.id)['records']
      pp results
    rescue AhaApi::NotFound
      return # Ignore stories that we don't have Aha! features for.
    end
  end

  def sync_requirements feature
    return unless payload.feature.requirements
    payload.feature.requirements.each do |requirement|
      workitem_resource.create data.project, data.requirement_mapping, Hash[
        "System.Title" => requirement.name,
        "System.Description" => requirement.description.body,
      ], [
        {
          :rel => "System.LinkTypes.Hierarchy-Forward",
          :url => feature.url
        }
      ]
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
end
