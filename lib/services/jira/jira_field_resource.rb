class JiraFieldResource < JiraResource
  def all
    unless @fields
      prepare_request
      response = http_get field_url
      process_response(response, 200) do |fields|
        @fields = fields
      end
    end
    @fields
  end

  def create(field)
    prepare_request
    response = http_post field_url, field.to_json
    process_response(response, 201) do |new_field|
      logger.info("Created field #{new_field.inspect}")
      return new_field.id
    end
  end

  def epic_name_field
    custom_schema_field("com.pyxis.greenhopper.jira:gh-epic-label")
  end

  def epic_link_field
    custom_schema_field("com.pyxis.greenhopper.jira:gh-epic-link")
  end

  def aha_position_field
    find_in_fields do |field|
      field.name == "Aha! Position" || field.name == "Aha! Rank"
    end
  end

  def aha_reference_field
    find_in_fields do |field|
      field.name == "Aha! Reference"
    end
  end

  def story_points_field
    find_in_fields do |field|
      field.name == "Story Points"
    end
  end

  def add_to_default_screen(field_id)
    prepare_request
    response = http_post("#{api_url}/screens/addToDefault/#{field_id}")
    # Ignore the response - this API is broken, it doesn't return JSON.
  end

private

  def custom_schema_field(schema)
    find_in_fields do |field|
      field.schema && field.schema.custom == schema
    end
  end

  def find_in_fields
    field = all.find { |field| yield(field) }
    field && field.id
  end

  def field_url
    "#{api_url}/field"
  end

end
