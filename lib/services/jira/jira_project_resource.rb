class JiraProjectResource < JiraResource
  def all(meta_data)
    prepare_request
    response = http_get("#{api_url}/issue/createmeta?expand=projects.issuetypes.fields")
    projects = []
    process_response(response, 200) do |meta|
      meta.projects.each do |project|
        issue_types = project.issuetypes.collect do |issue_type|
          Hashie::Mash.new(id: issue_type.id, name: issue_type.name)
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
              statuses << Hashie::Mash.new(id: status.id, name: status.name)
            end
          end
          issue_types.each do |issue_type|
            issue_type.statuses = statuses
          end
        else
          process_response(status_response, 200) do |status_meta|
            status_meta.each do |status_issue_type|
              statuses = []
              status_issue_type.statuses.each do |status|
                statuses << Hashie::Mash.new(id: status.id, name: status.name)
              end
              issue_type = issue_types.find { |i| i.id == status_issue_type.id }
              issue_type.statuses = statuses if issue_type
            end
          end
        end

        projects << Hashie::Mash.new(id: project.id, key: project[:key],
          name: project.name, issue_types: issue_types)
      end
    end
    projects
  end

protected

  def issue_field_capabilities(meta_data, issue_type)
    # Check for fields that we use.
    fields =
      if issue_type.fields.present?
        {
          has_field_fix_versions: issue_type.fields.fixVersions.present?,
          has_field_aha_reference: issue_type.fields[meta_data.aha_reference_field].present?,
          has_field_story_points: issue_type.fields[meta_data.story_points_field].present?,
          has_field_epic_name: issue_type.fields[meta_data.epic_name_field].present?,
          has_field_epic_link: issue_type.fields[meta_data.epic_link_field].present?,
          has_field_labels: issue_type.fields.labels.present?,
          has_field_time_tracking: issue_type.fields.timetracking.present?
        }
      else
        Hash.new
      end

    Hashie::Mash.new(subtask: issue_type.subtask).merge(fields)
  end
  
  def issue_fields(issue_type)
    fields =
      if issue_type.fields.present?
        {fields:
          issue_type.fields.collect do |field_key, field|
            {
              key: field_key, 
              name: field.name,
              type: field.schema.type,
              sub_type: field.schema.items
            }
          end
        }
      else
        Hash.new
      end

    Hashie::Mash.new(fields)
  end
end
