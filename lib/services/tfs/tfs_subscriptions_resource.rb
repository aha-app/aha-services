class TFSSubscriptionsResource < TFSResource

  API_VERSION = "1.0"

  def all
    url = mstfs_url "hooks/subscriptions"
    response = http_get url
    process_response response do |body|
      return body.value
    end
  end

  def create project_id, callback_url
    url = mstfs_url "hooks/subscriptions"
    body = {
      "consumerActionId" => "httpRequest",
      "consumerId" => "webHooks",
      "eventType" => "workitem.updated",
      "publisherId" => "tfs",
      "resourceVersion" => "1.0",
      "consumerInputs" => {
        "messagesToSend" => "none",
        "detailedMessagesToSend" => "none",
        "url" => callback_url
      },
      "publisherInputs" => {
        "projectId" => project_id
      }
    }.to_json
    response = http_post url, body
    process_response response
  end
end
