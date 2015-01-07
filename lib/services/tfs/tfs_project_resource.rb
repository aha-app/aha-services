class TFSProjectResource < TFSResource

  def all
    response = http_get mstfs_url("projects")
    process_response response do |body|
      projects = Hashie::Mash.new
      body.value.each do |project|
        projects[project.id] = Hashie::Mash.new({:id => project.id, :name => project.name})
      end
      projects
    end
  end
end
