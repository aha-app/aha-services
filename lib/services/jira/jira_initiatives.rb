module AhaServices::JiraInitiatives
  def create_or_update_initiative(initiative)
    issue_info = get_existing_issue_info(initiative)
    if issue_info
      update_issue_for_initiative(issue_info, initiative)
    elsif initiative_issue_type
      create_issue_for_initiative(initiative, initiative_issue_type)
    else
      raise AhaService::RemoteError, "Could not create initiative #{initiative.id} because no Issue Type was found for Initiatives."
    end
  end
  
  def create_issue_for_initiative(initiative, issue_type)
    logger.info("Creating issue for initiative #{initiative.id}")
    
    issue = initiative_fields(initiative: initiative)

    if issue_type["name"] == "Epic"
      # Attempting to set the "Epic Name" field on anything other than an epic causes errors.
      issue.fields.merge!({
        meta_data.epic_name_field => initiative.name
      })
    end

    issue.fields.merge!({
      issuetype: { id: issue_type.id }
    })

    new_issue = issue_resource.create(issue)
    upload_attachments(initiative.description.attachments, new_issue.id)
    integrate_initiative_with_jira_issue(initiative, new_issue)

    logger.info("Created initiative issue #{new_issue[:key]}")

    new_issue
  end

  def update_issue_for_initiative(issue_info, initiative)
    logger.info("Updating issue #{issue_info[:key]} for initiative #{initiative.id}")

    issue = initiative_fields(initiative: initiative)

    issue_resource.update(issue_info.id, issue)

    initiative.attachments ||= [] # initiatives aren't sent with attachments of their own
    update_attachments(issue_info.id, initiative)
    logger.info "Updated initiative issue #{issue_info[:key]}"

    issue
  end

  def initiative_fields(opts={})
    initiative = opts.fetch(:initiative)
    issue = Hashie::Mash.new({
      fields: {
        summary: resource_name(initiative),
        description: convert_html(initiative.description.body),
      }
    })

    issue.fields.merge!(aha_reference_fields(initiative, initiative_issue_type))
    issue.fields.merge!(mapped_custom_fields(initiative, initiative_issue_type, data.initiative_field_mapping))

    issue
  end
end
