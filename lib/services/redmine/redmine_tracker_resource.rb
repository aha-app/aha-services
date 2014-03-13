class RedmineTrackerResource < RedmineResource
  def all
    prepare_request
    response = http_get "#{@service.data.redmine_url}/trackers.json"
    process_response response, 200 do |body|
      @trackers = body['trackers']
    end
    @trackers
  end
end
