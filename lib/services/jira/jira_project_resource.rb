class JiraProjectResource < JiraResource
  def all(meta_data)
    @fields = {}
    @issue_type_sets = {}
    @status_sets = {}
    
    prepare_request
    response = http_get("#{api_url}/issue/createmeta?expand=projects.issuetypes.fields")
    projects = []
    process_response(response, 200) do |meta|
      meta.projects.each do |project|
        issue_types = project.issuetypes.collect do |issue_type|
          {'id' => issue_type.id, 'name'=> issue_type.name}
            .merge(issue_field_capabilities(meta_data, issue_type))
            .merge(issue_fields(issue_type))
        end

        # Get the statuses.
        status_response = http_get "#{api_url}/project/#{project['key']}/statuses"
        if status_response.status == 404
          # In Jira 5.0 the status is not associated with each issue type.
          statuses = []
          status_response = http_get "#{api_url}/status"
          process_response(status_response, 200) do |status_meta|
            status_meta.each do |status|
              statuses << {'id' => status.id, 'name' => status.name}
            end
          end
          statuses_hash = statuses.hash.to_s
          @status_sets[statuses_hash] ||= statuses
          issue_types.each do |issue_type|
            issue_type['statuses'] = statuses_hash
          end
        else
          process_response(status_response, 200) do |status_meta|
            status_meta.each do |status_issue_type|
              statuses = []
              status_issue_type.statuses.each do |status|
                statuses << {'id' => status.id, 'name' => status.name}
              end
              statuses_hash = statuses.hash.to_s
              @status_sets[statuses_hash] ||= statuses
              
              issue_type = issue_types.find { |i| i['id'] == status_issue_type.id }
              issue_type['statuses'] = statuses_hash if issue_type
            end
          end
        end

        issue_types_hash = issue_types.hash.to_s
        @issue_type_sets[issue_types_hash] ||= issue_types
        projects << {'id' => project.id, 'key' => project[:key],
          'name' => project.name, 'issue_types' => issue_types_hash}
      end
    end
    
    meta_data['fields'] = @fields
    meta_data['issue_type_sets'] = @issue_type_sets
    meta_data['status_sets'] = @status_sets
    
    projects
  end

protected

  def issue_field_capabilities(meta_data, issue_type)
    # Check for fields that we use.
    fields =
      if issue_type.fields.present?
        {
          'has_field_fix_versions' => issue_type.fields.fixVersions.present?,
          'has_field_aha_reference' => issue_type.fields[meta_data['aha_reference_field']].present?,
          'has_field_story_points' => issue_type.fields[meta_data['story_points_field']].present?,
          'has_field_epic_name' => issue_type.fields[meta_data['epic_name_field']].present?,
          'has_field_epic_link' => issue_type.fields[meta_data['epic_link_field']].present?,
          'has_field_labels' => issue_type.fields.labels.present?,
          'has_field_time_tracking' => issue_type.fields.timetracking.present?
        }
      else
        Hash.new
      end

    {'subtask' => issue_type.subtask}.merge(fields)
  end
  
  def issue_fields(issue_type)
    if issue_type.fields.present?
      field_set = issue_type.fields.collect do |field_key, field|
        @fields[field_key] ||= 
          {
            'name' => field.name,
            'type' => field.schema.type,
            'sub_type' => field.schema.items,
            'editor' => field.schema.custom || field.schema.system
          }
        field_key
      end
      {'fields' => field_set.sort}
    else
      {}
    end
  end
end
