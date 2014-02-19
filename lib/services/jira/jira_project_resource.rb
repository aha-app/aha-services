class JiraProjectResource < JiraResource
  def all
    prepare_request
    response = http_get("#{api_url}/issue/createmeta")
    projects = []
    process_response(response, 200) do |meta|
      meta['projects'].each do |project|
        issue_types = project['issuetypes'].collect do |issue_type|
          {id: issue_type['id'], name: issue_type['name'], 
            subtask: issue_type['subtask']}
        end
        
        # Get the statuses.
        status_response = http_get "#{api_url}/project/#{project['key']}/statuses"
        if status_response.status == 404
          # In Jira 5.0 the status is not associated with each issue type.
          statuses = []
          status_response = http_get "#{api_url}/status"
          process_response(status_response, 200) do |status_meta|      
            status_meta.each do |status|
              statuses << {id: status['id'], name: status['name']}
            end
          end
          issue_types.each do |issue_type|
            issue_type[:statuses] = statuses
          end
        else
          process_response(status_response, 200) do |status_meta|      
            status_meta.each do |status_issue_type|
              statuses = []
              status_issue_type['statuses'].each do |status|
                statuses << {id: status['id'], name: status['name']}
              end
              
              issue_type = issue_types.find {|i| i[:id] == status_issue_type['id']}
              issue_type[:statuses] = statuses if issue_type
            end
          end
        end
        
        projects << {id: project['id'], key: project['key'], 
          name: project['name'], issue_types: issue_types}
      end
    end
    projects
  end

  def statuses(project_key)
    prepare_request
    response = http_get("#{api_url}/project/#{project_key}/statuses")
    if response.status == 404
      # In Jira 5.0 the status is not associated with each issue type.
    else

    end
  end
end
