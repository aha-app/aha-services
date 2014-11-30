class TFSWorkitemtypeResource < TFSResource

  ALLOWED_CATEGORIES = %w(Microsoft.FeatureCategory Microsoft.RequirementCategory)

  def all project
    url = mstfs_project_url project, "wit/workitemtypes"
    response = http_get url
    process_response response do |body|
      return body.value
    end
  end

  def determin_possible_workflows meta_data
    state_sets = Hashie::Mash.new
    workflow_sets = Hashie::Mash.new
    meta_data.projects.each do |project|
      categories = get_categories project
      allowed_types = allowed_types_from_categories categories
      project_workitem_types = (all project.id).select{|wit| allowed_types.include?(wit.name)}
      workitem_type_set = []
      # For each workitem type in the project, determine the set of states
      # Then add it to the workitem type set of the project
      project_workitem_types.each do |workitem|
        states = workitem.transitions.map{|t| t[0]}.reject{|s| s == ""}.sort
        state_sets[states.hash] ||= states
        workitem_type_set << Hashie::Mash.new({ :name => workitem.name, :states => states.hash })
      end
      # Sort the workitem type set so that same sets will have same hashes
      workitem_type_set.sort_by!{|wit| wit.name}
      workflow_sets[workitem_type_set.hash] ||= workitem_type_set
      project[:workflow] = workitem_type_set.hash
    end
    meta_data[:state_sets] = state_sets
    meta_data[:workflow_sets] = workflow_sets
  end

  def get_categories project
    url = mstfs_project_url project.id, "wit/workitemtypecategories"
    response = http_get url
    process_response response do |body|
      return body.value.select{|c| ALLOWED_CATEGORIES.include?(c.referenceName)}
    end
  end

protected
  def allowed_types_from_categories categories
    categories.map{|c| c.workItemTypes.map{|wit| wit.name} }.flatten().uniq()
  end
end
