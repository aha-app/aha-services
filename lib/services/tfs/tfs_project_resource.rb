class TFSProjectResource < TFSResource

  def all
    response = http_get mstfs_url("projects")
    process_response response do |body|
      body.value.collect do |project|
        {id: project.id, name: project.name}
      end
    end
  end
end
