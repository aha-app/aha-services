class AhaServices::PivotalTracker < AhaService
  string :api_token, description: "API token from www.pivotaltracker.com"
  install_button
  select :project, collection: -> (meta_data, data) { meta_data.projects.collect { |p| [p.name, p.id] } },
    description: "Tracker project that this Aha! product will integrate with."
  select :integration,
    collection: ->(meta_data, data) { meta_data.projects.detect {|p| p.id.to_s == data.project.to_s }.integrations.collect{|p| [p.name, p.id] } },
    description: "Pivotal integration that you added for Aha!"
  select :mapping, collection: -> {
    [
      ["Feature -> Story, Requirement -> Story", 1],
      ["Feature -> Epic, Requirement -> Story", 2],
      ["Feature -> Story, Requirement -> Task", 3]
    ]
  }

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
      next unless change.kind == "story"

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

      if change.new_values and new_state = change.new_values.current_state
        # Update the status.
        api.put(resource.resource, {resource_type => {status: pivotal_to_aha_status(new_state)}})
      else
        # Unhandled change.
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

  def pivotal_to_aha_status(status)
    case status
      when "accepted" then "shipped"
      when "delivered" then "ready_to_ship"
      when "finished" then "in_progress"
      when "started" then "in_progress"
      when "rejected" then "in_progress"
      when "unstarted" then "scheduled"
      when "unscheduled" then "under_consideration"
    end
  end

end

