class RallyWebhookResource < RallyResource
  WEBHOOK_URL = "https://rally1.rallydev.com/notifications/api/v2/webhook"
	PROJECT_FIELD_UUID = "ae8ecc9f-b9a0-42a4-a6e3-c83d7f8a7070"

  # Rally requires you to pass in a key to access their API. You get the key by
  # setting basic auth and calling a certain endpoint.
  #
  # However, if you try using basic auth when hitting the webhook API, it will
  # fail.
  def http_get_no_basic(*args, &block)
    http_get(*args) do |req|
      req.headers.delete "Authorization"
      block.call(req) if block
    end
  end

  def http_patch_no_basic(*args, &block)
    http_patch(*args) do |req|
      req.headers.delete "Authorization"
      block.call(req) if block
    end
  end

  def http_post_no_basic(*args, &block)
    http_post(*args) do |req|
      req.headers.delete "Authorization"
      block.call(req) if block
    end
  end

  def http_delete_no_basic(*args, &block)
    http_delete(*args) do |req|
      req.headers.delete "Authorization"
      block.call(req) if block
    end
  end
  
  def webhook_url path
    get_security_token unless self.security_token
    joiner = (path =~ /\?/) ? "&" : "?"
    "#{WEBHOOK_URL}#{path}#{joiner}key=#{self.security_token}"
  end

  def all_webhooks
    process_response(http_get_no_basic(webhook_url("?start=1&pageSize=200"))) do |document|
      return document.Results
    end
  end

  def search_for_webhook(callback_url)
    all_webhooks.detect {|webhook| webhook.TargetUrl == callback_url}
  end

  def update_webhook webhook
    response = http_patch_no_basic(webhook_url("/#{webhook.ObjectUUID}")) do |req|
      req.body = hash_for_webhook.to_json
    end

    process_response(response)
  end

  def create_webhook
    response = http_post_no_basic(webhook_url("")) do |request|
      request.body = hash_for_webhook.to_json
    end

    process_response(response)
  end

  def destroy_webhook webhook
    response = http_delete_no_basic(webhook_url("/#{webhook.ObjectUUID}"))
    process_response(response)
  end

  def webhook_is_disabled
    !@service.data.integration_enabled
  end

  def selected_project_uuid
    project = @service.meta_data.projects.detect{|project| project.ObjectID == @service.data.project.to_i }
    
    if project
      project["_refObjectUUID"]
    else
      raise_config_error "Attempted to create or update a webhook without a project selected."
    end
  end

  def project_and_recursive_children project_uuid
    projects = @service.meta_data.projects

    return_projects = []

    return_projects << projects.detect {|project| project["_refObjectUUID"] == project_uuid }

    projects.select {|project| project["ParentUUID"] == project_uuid }.each do |child_project|
      return_projects.concat(project_and_recursive_children(child_project["_refObjectUUID"]))
    end

    return_projects
  end

  def hash_for_webhook
    expressions = project_and_recursive_children(selected_project_uuid).map do |project|
      {
        "AttributeID" => PROJECT_FIELD_UUID,
        "Operator" => "=",
        "Value" => project["_refObjectUUID"]
      }
    end

    Rails.logger.info "EXPRESSIONS: #{expressions.inspect}"

    {
      "AppName" => "Aha!",
      "AppUrl" => "http://www.aha.io",
      "TargetUrl" => @service.data.callback_url,
      "Name" => "Aha! Rally Integration #{@service.data.integration_id}",
      "Expressions" => expressions,
      "Disabled" => webhook_is_disabled
    }
  end
end

