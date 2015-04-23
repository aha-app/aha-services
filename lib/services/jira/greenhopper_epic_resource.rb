class GreenhopperEpicResource < JiraResource
  
  def add_story(issue_id, epic_key) 
    prepare_request
    response = http_put "#{api_url}/epics/#{epic_key}/add", {ignoreEpics: true, issueKeys: [issue_id]}.to_json
    process_response(response, 204)
  end

protected

  def api_url
    "#{@service.data.server_url}/rest/greenhopper/1.0"
  end

end