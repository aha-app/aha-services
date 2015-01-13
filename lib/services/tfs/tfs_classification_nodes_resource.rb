class TFSClassificationNodesResource < TFSResource

  def get_areas project
    url = mstfs_project_url project.id, "wit/classificationNodes/areas?$depth=10"
    response = http_get url
    process_response response do |body|
      recursivly_collect_areas body
    end
  end

  def get_areas_for_all_projects meta_data
    meta_data.projects.each do |id, project|
      project.areas = get_areas project
    end
  end

protected
  def recursivly_collect_areas area, prefix = ""
    name = prefix + area.name
    paths = [ name ]
    if area.hasChildren
      area.children.each do |child_area|
        paths += recursivly_collect_areas(child_area, name + "\\")
      end
    end
    paths
  end
end
