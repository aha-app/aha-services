class RallyProjectResource < RallyResource
  def all
    url = rally_url "/project?fetch=true"
    response = http_get url
    process_response response, 200 do |document|
      return document.QueryResult.Results.map{|project| project.slice("ObjectID", "_ref", "Name") }
    end
  end
end
