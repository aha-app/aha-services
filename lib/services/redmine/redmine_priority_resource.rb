class RedminePriorityResource < RedmineResource
  def all
    prepare_request
    response = http_get "#{@service.data.redmine_url}/enumerations/issue_priorities.json"
    process_response response, 200 do |body|
      @priorities = body['issue_priorities']
    end
    @priorities
  end
end
