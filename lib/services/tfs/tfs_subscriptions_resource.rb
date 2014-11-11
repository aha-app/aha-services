class TFSSubscriptionsResource < TFSResource

  API_VERSION = "1.0"

  def all
    url = mstfs_url "hooks/subscriptions"
    response = http_get url
    return [] unless response.status == 200
    parsed_body(response).value
  end

  def create_maybe callback_url
    subscriptions = all
    subscription = subscriptions.detect{ |s|
      s["publisherId"] == "tfs" and
      s["eventType"] == "workitem.updated" and
      s["consumerId"] == "webHooks" and
      s["consumerActionId"] == "httpRequest" and
      s["consumerInputs"]["url"] == callback_url
    }
    unless subscription then
      create callback_url
    else
      subscription
    end
  end

  def create callback_url
    url = mstfs_url "hooks/subscriptions"
    body = {
      "consumerActionId" => "httpRequest",
      "consumerId" => "webHooks",
      "eventType" => "workitem.updated",
      "publisherId" => "tfs",
      "resourceVersion" => "1.0-preview.2",
      "consumerInputs" => {
        "url" => callback_url
      }
    }.to_json
    response = http_post url, body
    if response.status == 200 then
      parsed_body response
    else
      raise "Error while creating subscription"
    end
  end
end
