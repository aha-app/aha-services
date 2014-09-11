class AhaServices::PivotalTracker < AhaService
  caption "Send features to Pivotal Tracker agile boards"
  
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
  internal :feature_status_mapping
  internal :feature_kind_mapping

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
        results = api.search_integration_fields(data.integration_id, "id", change.id)['records']
      rescue AhaApi::NotFound
        return # Ignore stories that we don't have Aha! features for.
      end

      if results
        results.each do |result|
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
    new_values.each do |change_kind, value|
      if kind == "story"
        if change_kind == "current_state"
          api.put(resource, { resource_type => { workflow_status: pivotal_to_aha_category(value) } })
        elsif change_kind == "name"
          api.put(resource, { resource_type => { name: value } })
        elsif change_kind == "description"
          api.put(resource, { resource_type => { description: value } })
        end
      elsif kind == "task" && change_kind == "complete" && value == true
        api.put(resource, {resource_type => { workflow_status: {category: "done" }}})
      elsif kind == "task" && change_kind == "complete" && value == false
        api.put(resource, {resource_type => { workflow_status: {category: "initial" }}})
      end
    end
  end

  def pivotal_to_aha_category(status)
    if data.feature_statuses
      data.feature_statuses[status]
    else
      {category: status_mapping[status]}
    end
  end

  def status_mapping
    {"accepted" => "shipped", "delivered" => "done", "finished" => "in_progress", "started" => "in_progress", "rejected" => "in_progress", "unstarted" => "initial", "unscheduled" => "initial"}
  end

end

