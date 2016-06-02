class RallyPortfolioItemResource < RallyResource

  def get_all_requirement_custom_fields
    path = "/typedefinitions?" + {
      start: 1,
      pagesize: 200,
      query: '(Name = "Hierarchical Requirement")',
      fetch: "true"
    }.to_query

    # Return our type definitions including their custom fields if they have any
    process_response(http_get(rally_secure_url(path))) do |response|
      type_definition = response.QueryResult.Results.first

      unless type_definition
        raise AhaService::RemoteError, "No User Story type was found"
      end

      custom_fields_for_type_definition(type_definition)
    end
  end

  def get_all_portfolio_items
    path = "/typedefinitions?" + {
      start: 1,
      pagesize: 200,
      query: '((TypePath contains PortfolioItem) AND (Ordinal >= 0))',
      fetch: "true"
    }.to_query

    # Return our type definitions including their custom fields if they have any
    process_response(http_get(rally_secure_url(path))) do |response|
      response.QueryResult.Results.sort_by do |type_definition|
        type_definition.Ordinal # Lowest Ordinal => Lowest unit on the heirarchy.
      end.map do |type_definition|
        # Add the definitions custom fields
        custom_fields = custom_fields_for_type_definition(type_definition)
        type_definition["CustomFields"] = custom_fields
        type_definition
      end
    end
  end

  private

  def custom_fields_for_type_definition(definition)
    # We need to crawl each type definition to get the potential custom fields
    url = "#{definition["Attributes"]["_ref"]}?" + {
      start: 1,
      pagesize: 200 # TODO - try to filter the query with "Custom = true"
    }.to_query

    process_response(http_get(url)) do |response|
      # We only want the custom fields, so filter on the Custom attribute.
      response["QueryResult"]["Results"].select { |attr| attr["Custom"] }.map do |attr|
        attr.slice("AttributeType", "Name", "ElementName")
      end
    end
  end
end

