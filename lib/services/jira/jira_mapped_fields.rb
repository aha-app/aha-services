module JiraMappedFields
  def field_mappings_for(resource)
    if resource == @feature
      data.field_mapping || []
    else
      data.requirement_field_mapping || data.field_mapping || []
    end
  end
  
  def mapped_custom_fields(resource, issue_type)
    custom_fields = Hash.new

    field_mappings_for(resource).each do |field_mapping|
      next unless field_mapping.is_a? Hashie::Mash
      info = jira_field_info(field_mapping.jira_field)
      if info
        value = custom_field_for_resource(resource, field_mapping.aha_field, info)
        custom_fields[field_mapping.jira_field] = value if value
      else
        logger.warn("JIRA field information not found - use Test Connection button again: #{field_mapping.jira_field}")
      end
      
    end

    custom_fields
  end
  
  def custom_field_for_resource(resource, aha_field, jira_type_info)
    return nil unless resource.custom_fields # We only have custom fields for Requirements.
    
    field = resource.custom_fields.find {|field| field['key'] == aha_field}

    if field
      aha_type_to_jira_type(field.value, field.type, jira_type_info, aha_field, field)
    else
      nil
    end
  end

  def aha_type_to_jira_type(aha_value, aha_type, jira_type_info, aha_field, field)
    case jira_type_info.type
    when "string"
      v = aha_type_to_string(aha_type, aha_value)
      if jira_type_info.editor == "com.atlassian.jira.plugin.system.customfieldtypes:select"
        {value: v}
      elsif jira_type_info.editor == "com.atlassian.jira.plugin.system.customfieldtypes:radiobuttons"
        {value: v}
      elsif jira_type_info.editor == "com.intenso.jira.plugin.dynamic-forms:dynamic-select-customfield"
        {value: v}
      else
        v
      end
    when "number"
      aha_type_to_number(aha_type, aha_value, jira_type_info, aha_field)
    when "array"
      aha_type_to_array(aha_type, aha_value, jira_type_info)
    when "priority"
      {name: aha_type_to_string(aha_type, aha_value)}
    when "option"
      {value: aha_type_to_string(aha_type, aha_value)}
    when "user"
      if jira_type_info.editor == "com.atlassian.jira.plugin.system.customfieldtypes:userpicker"
        {name: aha_type_to_user(aha_type, field)}
      else
        {name: aha_type_to_string(aha_type, aha_value)}
      end
    else
      logger.debug("Using default field type mapping for Aha field '#{aha_field}' with value '#{aha_type}' to '#{jira_type_info.type}'")
      aha_value
    end
  end
  
  def aha_type_to_string(aha_type, aha_value)
    case aha_type
    when "html", "note"
      convert_html(aha_value)
    when "array"
      aha_value.join(",")
    else
      logger.debug("Using default string mapping for '#{aha_type}'")
      aha_value.to_s
    end
  end

  def aha_type_to_user(aha_type, field)
    key = nil
    email_add = aha_type == "string" ? field.value : field.email_value
    Array(email_add).each do |email|
      key = user_resource.picker(email.strip).try(:[], :key)
    end.compact
    key
  end
  
  def aha_type_to_number(aha_type, aha_value, jira_type_info, aha_field)
    unless aha_value.respond_to?(:to_f) # Custom fields with multiple selects are arrays and dont respond to to_f
      raise AhaService::RemoteError, "Aha! Field '#{aha_field}' cannot be mapped to JIRA field '#{jira_type_info.name}'"
    end

    value = aha_value.to_f
    unless value.to_s == aha_value
      logger.warn "Aha! Field '#{aha_field}' with value '#{aha_value}' does not map cleanly to a number for JIRA field '#{jira_type_info.name}'"
    end
    value
  end
  
  def aha_type_to_array(aha_type, aha_value, jira_type_info)
    values = case aha_type
      when "array"
        aha_value
      else
        [aha_value]
      end

    # Recurse for the array 
    case jira_type_info.sub_type
    when "component"
      values.collect {|v| {name: v} }
    when "option", "string"
      multicheckboxes = "com.atlassian.jira.plugin.system.customfieldtypes:multicheckboxes"
      multiselect = "com.atlassian.jira.plugin.system.customfieldtypes:multiselect"
      case jira_type_info.editor
      when multicheckboxes, multiselect
        values.collect {|v| {value: v} }
      else
        values
      end
    else
      values
    end
  end
  
  def jira_field_info(jira_field)
    meta_data.fields[jira_field]
  end
  
end
