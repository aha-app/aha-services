class RallyProjectResource < RallyResource
  def all
    url = rally_url "/project?fetch=true&pagesize=100"
    response = http_get url
    process_response response do |document|
      return document.QueryResult.Results.map{|project| project.slice("ObjectID", "_ref", "Name") }
    end
  end
end
