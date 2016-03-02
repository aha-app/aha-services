class RallyStateResource < RallyResource
  def get_all_states
    (portfolio_item_states + user_story_states).inject({}) do |hsh, (type, state_name)|
      hsh[type] ||= []
      hsh[type].push(state_name)
      hsh
    end
  end

  def portfolio_item_states
    path = "/state?" + {
      start: 1,
      pagesize: 200,
      order: "OrderIndex",
      fetch: "true"
    }.to_query

    process_response(http_get(rally_secure_url(path))) do |response|
      return response.QueryResult.Results.map {|state| state.TypeDef && [state.TypeDef["_refObjectName"], state.Name]}.compact
    end
  rescue 
    []
  end

  def user_story_states
    path = "/typedefinition?" + {
      query: "(ElementName = HierarchicalRequirement)",
      fetch: "true",
    }.to_query
    hr_typedef = process_response(http_get(rally_secure_url(path))).QueryResult.Results.first

    attribute_query = {
      start: 1,
      pagesize: 200,
      fetch: "true"
    }.to_query

    schedule_state_attr = process_response(http_get(hr_typedef.Attributes["_ref"] + "?" + attribute_query)).QueryResult.Results.detect{|attr| attr.ElementName == "ScheduleState" }

    process_response(http_get(schedule_state_attr.AllowedValues["_ref"])).QueryResult.Results.map do |state|
      ["UserStory", state.StringValue]
    end
  end
end
