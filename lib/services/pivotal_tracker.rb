class AhaServices::PivotalTracker < AhaService
  string :api_token, description: "API token from user profile screen at www.pivotaltracker.com"
  install_button
  select :project, collection: -> (meta_data, data) { meta_data.projects.collect { |p| [p.name, p.id] } },
    description: "Tracker project that this Aha! product will integrate with."
  select :integration,
    collection: ->(meta_data, data) { meta_data.projects.detect {|p| p.id.to_s == data.project.to_s }.integrations.collect{|p| [p.name, p.id] } },
    description: "Pivotal integration that you added for Aha!"
  select :mapping, collection: [
        ["Feature -> Story, Requirement -> Story", "story-story"],
        ["Feature -> Epic, Requirement -> Story", "epic-story"],
        ["Feature -> Story, Requirement -> Task", "story-task"]
      ],
    description: "Choose how features and requirements in Aha! will map to epics, stories and tasks in Pivotal Tracker."

  callback_url description: "URL to add to the Activity Web Hook section in Pivotal Tracker using v5."

  def receive_installed
    meta_data.projects = project_resource.all
  end

  def receive_create_feature
    feature_and_requirement_mapping_resource.create_feature(payload.feature)
  end

  def receive_update_feature
    feature_and_requirement_mapping_resource.update_feature(payload.feature)
  end

  def receive_webhook
    payload.changes.each do |change|
      next unless change.kind == "story" || change.kind == "task"

      begin
        result = api.search_integration_fields(data.integration_id, "id", change.id)
      rescue AhaApi::NotFound
        return # Ignore stories that we don't have Aha! features for.
      end

      if result.feature
        resource = result.feature
        resource_type = "feature"
      elsif result.requirement
        resource = result.requirement
        resource_type = "requirement"
      else
        logger.info("Unhandled resource type")
        next
      end

      if change.new_values
        apply_change change.kind, change.new_values, resource.resource, resource_type
      end
    end
  end

protected

  def project_resource
    @project_resource ||= PivotalTrackerProjectResource.new(self)
  end

  def feature_and_requirement_mapping_resource
    @feature_and_requirement_mapping_resource ||= PivotalTrackerFeatureAndRequirementMappingResource.new(self, data.project)
  end

  def apply_change(kind, new_values, resource, resource_type)
    if kind == "story" && new_state = new_values.current_state
      api.put(resource, {resource_type => { category: pivotal_to_aha_category(new_state) }})
    elsif kind == "task" && ["true", true].include?(new_values.complete)
      api.put(resource, {resource_type => { category: "shipped" }})
    end
  end

  def pivotal_to_aha_category(status)
    case status
      when "accepted" then "shipped"
      when "delivered" then "done"
      when "finished" then "in_progress"
      when "started" then "in_progress"
      when "rejected" then "in_progress"
      when "unstarted" then "initial"
      when "unscheduled" then "initial"
    end
  end

end

