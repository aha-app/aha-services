class RallyWorkspaceResource < RallyResource
  def all
    workspaces = []
    start = 1
    total_results = 0
    process_response(http_get(rally_url_without_workspace("/subscription"))) do |response|
      workspaces_url = response.Subscription.Workspaces["_ref"]
      loop do
        url = "#{workspaces_url}?pagesize=100&start=#{start}"
        response = http_get url
        process_response response do |document|
          total_results = document.QueryResult.TotalResultCount
          start += document.QueryResult.PageSize
          document.QueryResult.Results.each do |workspace_result|
            workspace = workspace_result.slice("ObjectID", "Name")
            configuration_url = workspace_result.WorkspaceConfiguration["_ref"]
            workspace["Configuration"] = process_response(http_get(configuration_url))
            workspaces.push(workspace)
          end
        end
        break if start >= total_results
      end
    end

    workspaces.sort_by {|w| w["Name"]}
  end
end
