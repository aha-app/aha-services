module AhaServices::RallyWebhook
  def create_or_update_webhook
    # Find the webhook that points at this integration
    current_webhook = rally_webhook_resource.search_for_webhook(data.callback_url)

    if current_webhook
      logger.info "Updating webhook #{current_webhook.ObjectUUID} for integration: #{data.integration_id}"
      update_webhook current_webhook
    else
      logger.info "Creating webhook for integration: #{data.integration_id}"
      create_webhook
    end
  end

  def create_webhook
    rally_webhook_resource.create_webhook
  end

  def update_webhook current_webhook
    rally_webhook_resource.update_webhook current_webhook
  end

  def destroy_webhook
    current_webhook = rally_webhook_resource.search_for_webhook(data.callback_url)
    if current_webhook
      rally_webhook_resource.destroy_webhook(current_webhook)
    end
  end

  def update_record_from_webhook(payload)
    results = api.search_integration_fields(data.integration_id, "id", payload.ObjectID)

    results.each do |result|
      if result.feature
        resource = result.feature
        resource_type = "feature"
      elsif result.requirement
        resource = result.requirement
        resource_type = "requirement"
      else
        logger.info "Unhandled resource type for webhook: #{result.inspect}"
      end

      logger.info "Received webhook to update #{resource_type}:#{resource.id}"
      api.put(resource.resource, { resource_type => {
        description: payload.Description,
        name: payload.Name,
        workflow_status: map_status(payload.Status)
      }})
    end
  rescue Api::NotFound
  end

  def map_status(status)
    #TODO
    status
  end
end

