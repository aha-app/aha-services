module JiraMappedFields
  def mapped_custom_fields(resource, issue_type)
    custom_fields = Hash.new
    
    (data.field_mapping || []).each do |field_mapping|
      next unless field_mapping.is_a? Hashie::Mash

      info = jira_field_info(field_mapping.jira_field, issue_type)
      if info
        value = custom_field_for_resource(resource, field_mapping.aha_field, info.type, info.sub_type)
        custom_fields[field_mapping.jira_field] = value if value
      else
        Rails.logger.warn("JIRA field information not found - use Test Connection button again: #{field_mapping.jira_field}")
      end
      
    end

    custom_fields
  end
  
  def custom_field_for_resource(resource, aha_field, jira_field, issue_type)
    return nil unless resource.custom_fields # We only have custom fields for Requirements.
    
    field = resource.custom_fields.find {|field| field['key'] == aha_field}
    if field
      aha_type_to_jira_type(field.value, field.type, jira_field, issue_type)
    else
      nil
    end
  end
  
  def aha_type_to_jira_type(aha_value, aha_type, jira_type, jira_sub_type = nil)
    case jira_type
    when "string"
      aha_type_to_string(aha_type, aha_value)
    when "number"
      aha_type_to_number(aha_type, aha_value)
    when "array"
      aha_type_to_array(aha_type, aha_value, jira_sub_type)
    when "priority"
      {name: aha_type_to_string(aha_type, aha_value)}
    else
      logger.debug("Using default field type mapping for '#{aha_type}' to '#{jira_type}'")
      aha_value
    end
  end
  
  def aha_type_to_string(aha_type, aha_value)
    case aha_type
    when "html"
      convert_html(aha_value)
    when "array"
      aha_value.join(",")
    else
      logger.debug("Using default string mapping for '#{aha_type}'")
      aha_value
    end
  end
  
  def aha_type_to_number(aha_type, aha_value)
    aha_value.to_i
  end
  
  def aha_type_to_array(aha_type, aha_value, jira_sub_type)
    values = case aha_type
      when "array"
        aha_value
      else
        [aha_value]
      end

    # Recurse for the array 
    case jira_sub_type
    when "component"
      values.collect {|v| {name: v} }
    else
      values
    end
  end
  
  def jira_field_info(jira_field, issue_type)
    if issue_type and field = issue_type.fields.find{ |f| f['key'] == jira_field }
      field
    end
  end
  
end