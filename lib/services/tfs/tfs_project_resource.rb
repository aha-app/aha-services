class TFSProjectResource < TFSResource

  def all
    response = http_get mstfs_url("projects")
    found_resource(response).value.collect do |project|
      {id: project.id, name: project.name}
    end
  end
end
