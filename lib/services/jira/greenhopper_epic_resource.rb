class GreenhopperEpicResource < JiraResource
  
  def add_story(issue_id, epic_key) 
    prepare_request
    if jira_connect_resource?
      response = http_post "#{@service.data.server_url}/rest/agile/1.0/epic/#{epic_key}/issue", {issues: [issue_id]}.to_json
    else
      response = http_put "#{@service.data.server_url}/rest/greenhopper/1.0/epics/#{epic_key}/add", {ignoreEpics: true, issueKeys: [issue_id]}.to_json
    end  
    
    process_response(response, 204, 200)
  end

end