class RallyProjectResource < RallyResource
  def all
    projects = []
    start = 1
    total_results = 0
    loop do 
      url = rally_url "/projects?fetch=true&pagesize=100&start=#{start}"
      response = http_get url
      process_response response do |document|
        total_results = document.QueryResult.TotalResultCount
        start += document.QueryResult.PageSize
        projects.concat(document.QueryResult.Results.map{|project| project.slice("ObjectID", "_ref", "Name", "_refObjectUUID", "Parent") })
      end
      break if start >= total_results
    end

    projects.each do |project|
      project["ParentUUID"] = project.delete("Parent").try(:"_refObjectUUID")
    end
    projects.sort_by {|r| r["Name"] }
  end
end
