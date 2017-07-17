class P2PMFeatureMappingResource < P2PMResource

  def create table, aha_feature
    sec_token = get_security_token
    #puts aha_feature
    # Get List of tables to get the UID of the TFS_DEV_MANAGER table
    dev_id = get_table_id("PMT_TFS_DEV_MANAGER", sec_token)
    puts dev_id
    http.headers["Authorization"] = "Bearer " + sec_token
    response = http_get @service.data.data_url + "/api/1.0/workflow/pmtable/"+ dev_id + '/data?q={"where": {"product": "' + aha_feature.release.project.name + '"}}'
    dev_manager = nil
    process_response response do |body|
      parsed = JSON.parse(body)
      #logger.debug "Body: #{body}\n"
      #logger.debug "Parsed body: #{parsed}\n"
      dev_manager = parsed["rows"][0]["name"]
    end    
    puts dev_manager
    puts aha_feature.workflow_kind.name
    puts aha_feature.release.project.name
    if aha_feature.workflow_kind.name != 'Research'
      # Get the DEV_MANGER from the TABLE for the Aha project
      body = {
        "ID" => nil,
        "REPRO_STEPS" => get_custom_field_value(aha_feature,"bug_repro_steps"),
        "SEVERITY" => get_custom_field_value(aha_feature,"bug_severigy"),
        "VERSION_FOUND_IN" => get_custom_field_value(aha_feature,"bug_version_found_in"),
        "CUSTOMER" => get_custom_field_value(aha_feature,"customer"),
        "CUSTOMER_PRIORITY" => get_custom_field_value(aha_feature,"customer_priority"),
        "OWNER" => get_custom_field_value(aha_feature,"salesforce_case_owner"),
        "SALESFORCE_ID" => get_custom_field_value(aha_feature,"salesforce_id"),
        "AHA_ID" => aha_feature.reference_num,
        "DEV_MANAGER" => dev_manager,
        "TITLE" => aha_feature.name,
        "PRODUCT" => aha_feature.release.project.name
      }
      #add_default_fields(body)
      
      # create new workitem in TFS
      created_workitem = workitem_resource.create table, body, sec_token
      created_case = workitem_resource.create_case aha_feature, sec_token
      #resp = workitem_resource.update_case created_case.app_uid, sec_token
      #puts resp
      #logger.debug("created_case:\n\n#{created_case}")
      # add integration field to workitem in aha
      api.create_integration_fields("features", aha_feature.reference_num, @service.data.integration_id, {id: created_workitem.id})
      # create a workitem in TFS for each requirement
      #create_and_link_requirements project, created_workitem, aha_feature.requirements
      # upload all attachments to TFS and link them to the workitem
      #create_attachments created_workitem, (aha_feature.attachments | aha_feature.description.attachments)
      return created_workitem
    end
  end

  def update workitem_id, aha_feature, table
    puts aha_feature.workflow_kind.name
    if aha_feature.workflow_kind.name != 'Research'
      sec_token = get_security_token
      workitem = workitem_resource.by_id workitem_id, table, sec_token
      puts workitem["rows"][0]["title"]
      # determine changes
      patch_set = []
      if workitem["rows"][0]["title"] != aha_feature.name then
        patch_set ='{"ID":"' + workitem_id +'","TITLE":"' + aha_feature.name + '"}'
      end
      puts patch_set
      # if workitem.fields["System.Description"] != aha_feature.description.body then
      #   patch_set << {
      #     :op => :replace,
      #     :path => "/fields/System.Description",
      #     :value => aha_feature.description.body
      #   }
      # end
      # update the feature
      workitem_resource.update workitem["rows"][0]["id"], patch_set, table, sec_token
      # update associated requirements
      # aha_feature.requirements.each do |requirement|
      #   requirement_mapping_resource.create_or_update(@service.data.project, workitem, requirement)
      # end
      # Add new attachments
      #create_attachments(workitem, (aha_feature.attachments | aha_feature.description.attachments))
    end
  end

  def update_aha_feature aha_feature, workitem
    changes = {}
    if aha_feature.name != workitem.fields["System.Title"]
      changes[:name] = workitem.fields["System.Title"]
    end
    if aha_feature.description.body != workitem.fields["System.Description"]
      changes[:description] = workitem.fields["System.Description"]
    end
    new_status = tfs_to_aha_status workitem.fields["System.State"]
    if aha_feature.workflow_status.id != new_status
      changes[:workflow_status] = new_status
    end
    if changes.length > 0
      api.put aha_feature.resource, { :feature => changes }
    end
  end

protected
  def add_default_fields(body)
    (@service.data.feature_default_fields || []).each do |field_mapping|
      next unless field_mapping.is_a? Hashie::Mash
      
      body[field_mapping.field] = field_mapping.value
    end
  end

  def create_and_link_requirements project, workitem, requirements
    requirements.each do |requirement|
      requirement_mapping_resource.create_or_update project, workitem, requirement
    end
  rescue AhaService::RemoteError => e
    logger.error e.message
  end

  def table
    @service.data.table
  end

  def tfs_to_aha_status status
    @service.data.feature_status_mapping[status]
  end

  def workitem_resource
    @workitem_resource ||= P2PMWorkItemResource.new(@service)
  end

  def get_custom_field_value(resource, key)
    field = resource.custom_fields.find {|field| field['key'] == key}
    if field
      field.value
    else
      nil
    end
  end

  def get_table_id(table_name, sec_token)
    http.headers["Authorization"] = "Bearer " + sec_token
    response = http_get @service.data.data_url + "/api/1.0/workflow/pmtable"
    process_response response do |body|
      
      tables = Hashie::Mash.new
      parsed = JSON.parse(body)
      table_id = nil
      parsed.each do |table|
        if table['pmt_tab_name'] == table_name
          table_id = table['pmt_uid']
        end
      end
      table_id
    end
  end

end
