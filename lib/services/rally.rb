class AhaServices::Rally < AhaService
  caption "Send releases, features and requirements to Rally"

  string :user_name, description: "The username for the Rally account."
  password :user_password

  install_button

  select :project, description: "The Rally project that this Aha! product will integrate with.", collection: -> (meta_data,data) {
    return [] unless meta_data and meta_data.projects
    meta_data.projects.collect {|p| [p.Name, p.ObjectID] }
  }

  # There is no status mapping until Rally supports webhooks.
  #internal :feature_status_mapping
  #internal :requirement_status_mapping

  def receive_installed
    projects = rally_project_resource.all
    meta_data.projects = projects
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

  def rally_hierarchical_requirement_resource
    @rally_hierarchical_requirement_resource ||= RallyHierarchicalRequirementResource.new self
  end

  def rally_portfolio_item_resource
    @rally_portfolio_item_resource ||= RallyPortfolioItemResource.new self
  end
end
