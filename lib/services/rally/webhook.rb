module AhaServices::RallyWebhook
  def create_or_update_webhooks
    rally_webhook_resource.upsert_webhooks
  end

  def destroy_webhooks
    rally_webhook_resource.destroy_webhooks
  end

  def update_record_from_webhook(payload, data=nil)
    raw_state_map = {}
    new_state = Hashie::Mash.new(Hash[ payload.message.state.map do |_, attribute|
      value = attribute.value
      raw_state_map[attribute.name] = value
      # User story webhooks get passed back as a status object, with a nested value
      if value.is_a? Hashie::Mash
        value = value.name
      end
      [attribute.name, value]
    end ])

    results = api.search_integration_fields(data.integration_id, "id", new_state.ObjectID)["records"] rescue []

    results.each do |result|
      resource = nil
      resource_type = nil
      if result.feature
        resource = result.feature
        resource_type = "feature"
        status_mappings = data.feature_statuses
      elsif result.requirement
        resource = result.requirement
        resource_type = "requirement"
        status_mappings = data.requirement_statuses
      else
        logger.info "Unhandled resource type for webhook: #{result.inspect}"
      end

      next unless resource

      logger.info "Received webhook to update #{resource_type}:#{resource.id}"

      update_hash = {}
      update_hash[:description] = new_state["Description"] if new_state["Description"]
      update_hash[:name] = new_state["Name"] if new_state["Name"]
      if raw_state_map["Owner"] && raw_state_map["Owner"]["ref"]
        update_hash[:assigned_to_user] = {"email" => rally_user_resource.email_from_ref(raw_state_map["Owner"]["ref"])}
      else
        update_hash[:assigned_to_user] = nil
      end
      
      if data && (data.send_tags == "1")
        update_hash[:tags] = [] # there are no tags if they aren't in raw_state_map
        update_hash[:tags] = raw_state_map["Tags"].map(&:name) if raw_state_map["Tags"]
      end

      if resource_type == "feature"
        update_hash[:start_date] = normalize_date(new_state["PlannedStartDate"]) if new_state["PlannedStartDate"]
        update_hash[:due_date] = normalize_date(new_state["PlannedEndDate"]) if new_state["PlannedEndDate"]
      end
      status = extract_status new_state, status_mappings
      if status
        update_hash[:workflow_status] = status
      end
      api.put(resource.resource, { resource_type => update_hash })
    end
  rescue AhaApi::NotFound
    logger.warn "No record found for reference: #{new_state.ObjectID}"
  end

  # Rally sends dates back in GMT, which makes the date wrong for some customers.
  #
  # Pull the time zone for this workspace, and then map the date that we have been given into it
  def normalize_date(date)
    if zone = active_workspace_configuration["TimeZone"]
      Time.parse(date).in_time_zone(zone).to_date rescue Date.parse(date)
    else
      Date.parse(date)
    end
  end

  def extract_status new_state, status_mappings
    status_mappings ||= {}
    (new_state["State"] && (status_mappings[new_state["State"]])) || 
      (new_state["ScheduleState"] && (status_mappings[new_state["ScheduleState"]]))
  end

  def rally_user_resource
    @rally_user_resource ||= RallyUserResource.new self
  end
end

