class TFSWorkitemtypeResource < TFSResource

  def all project
    url = mstfs_project_url project, "wit/workitemtypes"
    response = http_get url
    process_response response do |body|
      return body.value
    end
  end

  def all_states project
    workitem_types = all project
    map = Hashie::Mash.new
    workitem_types.each do |wit|
      map[wit.name] = wit.transitions.map{|t| t[0]}.select{|s| s != ""}
    end
    map
  end

  def all_projects_all_states
    map = Hashie::Mash.new
    @service.meta_data.projects.each do |project|
      map[project.id] = all_states project.id
    end
    map
  end
end
