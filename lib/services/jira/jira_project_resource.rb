class JiraProjectResource < JiraResource
  def all
    prepare_request
    response = http_get("#{api_url}/issue/createmeta")
    projects = []
    process_response(response, 200) do |meta|
      meta['projects'].each do |project|
        issue_types = []
        
        # Get the statuses.
        status_response = http_get "#{api_url}/project/#{project['key']}/statuses"
        if status_response.status == 404
          # In Jira 5.0 the status is not associated with each issue type.
          status_response = http_get "#{api_url}/status"
          process_response(status_response, 200) do |status_meta|      
            statuses = []
            status_meta.each do |status|
              statuses << {id: status['id'], name: status['name']}
            end

            project['issuetypes'].each do |issue_type|
              issue_types << {id: issue_type['id'], name: issue_type['name'], 
                subtask: issue_type['subtask'], statuses: statuses}
            end
          end
        else
          process_response(status_response, 200) do |status_meta|      
            status_meta.each do |issue_type|
              statuses = []
              issue_type['statuses'].each do |status|
                statuses << {id: status['id'], name: status['name']}
              end
            
              issue_types << {id: issue_type['id'], name: issue_type['name'], 
                subtask: issue_type['subtask'], statuses: statuses}
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
