class RallyStateResource < RallyResource
  def get_all_states
    (portfolio_item_states + user_story_states).inject({}) do |hsh, (type, state_name)|
      hsh[type] ||= []
      hsh[type].push(state_name)
      hsh
    end
  end

  def portfolio_item_states
    params = {
      start: 1,
      pagesize: 200,
      order: "OrderIndex",
      fetch: "true"
    }

    if @service.data.workspace.present?
      params[:workspace] = RallyResource::API_URL + "/workspace/#{@service.data.workspace}"
    end

    path = "/state?" + params.to_query

    process_response(http_get(rally_secure_url_without_workspace(path))) do |response|
      return response.QueryResult.Results.map {|state| state.TypeDef && [state.TypeDef["_refObjectName"], state.Name]}.compact
    end
  rescue 
    []
  end

  def user_story_states
    params = {
      query: "(ElementName = HierarchicalRequirement)",
      fetch: "true",
    }

    if @service.data.workspace.present?
      params[:workspace] = RallyResource::API_URL + "/workspace/#{@service.data.workspace}"
    end

    path = "/typedefinitions?" + params.to_query

    hr_typedef = process_response(http_get(rally_secure_url_without_workspace(path))).QueryResult.Results.first

    attribute_query = {
      start: 1,
      pagesize: 200,
      fetch: "true"
    }

    if @service.data.workspace.present?
      attribute_query[:workspace] = RallyResource::API_URL + "/workspace/#{@service.data.workspace}"
    end

    schedule_state_attr = process_response(http_get(hr_typedef.Attributes["_ref"] + "?" + attribute_query.to_query)).QueryResult.Results.detect{|attr| attr.ElementName == "ScheduleState" }

    process_response(http_get(schedule_state_attr.AllowedValues["_ref"])).QueryResult.Results.map do |state|
      ["UserStory", state.StringValue]
    end
  end
end
