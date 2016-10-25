class AhaServices::Rally < AhaService
  caption "Send releases, features and requirements to Rally"

  string :user_name, description: "The username for the Rally account."
  password :user_password

  install_button

  select :workspace, description: "The Rally workspace containing the product Aha! will integrate with. After changing the workspace click the 'Test Connection' button to retrieve the projects for the workspace.", collection: -> (meta_data, data) {
    return [] unless meta_data && meta_data.workspaces
    meta_data.workspaces.collect{|p| [p.Name, p.ObjectID]}
  }

  select :project, description: "The Rally project that this Aha! product will integrate with. Click 'Test Connection' to refresh this list.", collection: -> (meta_data,data) {
    return [] unless meta_data && meta_data.projects
    meta_data.projects.collect {|p| [p.Name, p.ObjectID] }
  }

  include AhaServices::RallyWebhook

  select :feature_and_requirement_type, description: "Choose how Aha! features and requirements will map to Rally portfolio items or user stories.", collection: -> (meta_data, data) {
    return [] unless meta_data && meta_data.type_definitions
    type_definitions = meta_data.type_definitions
    user_stories = Hashie::Mash.new({Name: "User Story", ElementName: "UserStory"})
    2.times { type_definitions.unshift(user_stories) }

    meta_data.type_definitions.each_cons(2).collect {|r, f| ["Feature -> #{f.Name}, Requirement -> #{r.Name}", "#{f.ElementName}::#{r.ElementName}"] }
  }

  internal :feature_status_mapping
  internal :feature_default_fields
  internal :requirement_status_mapping
  internal :requirement_default_fields

  boolean :send_tags, description: "Check to synchronize Aha! tags and Rally Tags. We recommend enabling this for new integrations. Enabling this option once features are synced to Rally may cause tags in Aha! or tags in Rally to be removed from a feature if the corresponding tags or tag doesn't exist in the other system."

  callback_url description: "URL Rally will call to update Aha!. This is webhook is automatically installed in Rally for the selected project."

  def receive_installed
    projects = rally_project_resource.all
    meta_data.projects = projects
    meta_data.workspaces = rally_workspace_resource.all
    meta_data.type_definitions = rally_portfolio_item_resource.get_all_portfolio_items
    meta_data.state_definitions = rally_state_resource.get_all_states

    meta_data.custom_fields = {
      "UserStory" => rally_portfolio_item_resource.get_all_requirement_custom_fields
    }

    meta_data.type_definitions.each do |definition|
      meta_data.custom_fields[definition.Name] = definition.CustomFields
    end

    meta_data.install_successful = true
  end

  def feature_element_name
    @_feature_element_name ||= if data.feature_and_requirement_type.present?
      data.feature_and_requirement_type.split("::").first
    else
      "UserStory"
    end
  end

  def requirement_element_name
    @_requirement_element_name ||= if data.feature_and_requirement_type.present?
      data.feature_and_requirement_type.split("::").last
    else
      "UserStory"
    end
  end

  def receive_updated
    if meta_data.install_successful && data.project.to_i
      create_or_update_webhooks
    end
  end

  def receive_destroyed
    if meta_data.install_successful && data.project.to_i
      destroy_webhooks
    end
  end

  def receive_webhook
    update_record_from_webhook(payload)
  end

  def receive_create_release
    rally_release_resource.create payload.release
  end

  def receive_update_release
    rally_release_resource.update payload.release
  end

  def receive_create_feature
    rally_hierarchical_requirement_resource.create_from_feature payload.feature
  end

  def receive_update_feature
    rally_hierarchical_requirement_resource.update_from_feature payload.feature
  end

protected
  def rally_resource
    @rally_resource ||= RallyResource.new self
  end

  def rally_release_resource
    @rally_release_resource ||= RallyReleaseResource.new self
  end

  def rally_project_resource
    @rally_project_resource ||= RallyProjectResource.new self
  end

  def rally_workspace_resource
    @rally_workspace_resource ||= RallyWorkspaceResource.new self
  end

  def rally_hierarchical_requirement_resource
    @rally_hierarchical_requirement_resource ||= RallyHierarchicalRequirementResource.new self
  end

  def rally_portfolio_item_resource
    @rally_portfolio_item_resource ||= RallyPortfolioItemResource.new self
  end

  def rally_webhook_resource
    @rally_webhook_resource ||= RallyWebhookResource.new self
  end

  def rally_state_resource
    @rally_state_resource ||= RallyStateResource.new self
  end
end
