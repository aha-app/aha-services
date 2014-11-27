class TFSWorkitemtypeResource < TFSResource

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
      project_workitem_types = all project.id
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
end
