class TFSWorkitemtypeResource < TFSResource

  def all project
    url = mstfs_project_url project.id, "wit/workitemtypes"
    response = http_get url
    process_response response do |body|
      return body.value
    end
  end

  def determin_possible_workflows meta_data
    status_sets = Hashie::Mash.new
    workflow_sets = Hashie::Mash.new
    meta_data.projects.each do |id, project|
      workflow = get_workflow project
      workflow.feature_mappings.each do |name, wit|
        status_hash = wit.statuses.hash
        status_sets[status_hash] ||= wit.statuses
        wit.statuses = status_hash
      end
      workflow.requirement_mappings.each do |name, wit|
        status_hash = wit.statuses.hash
        status_sets[status_hash] ||= wit.statuses
        wit.statuses = status_hash
      end
      workflow_hash = workflow.hash
      workflow_sets[workflow_hash] ||= workflow
      project.workflow = workflow_hash
    end
    meta_data[:status_sets] = status_sets
    meta_data[:workflow_sets] = workflow_sets
  end

  def get_categories project
    url = mstfs_project_url project.id, "wit/workitemtypecategories"
    response = http_get url
    process_response response do |body|
      return body.value
    end
  end

protected
  def get_workflow project
    categories = get_categories project
    workitemtypes = all project
    feature_types = categories.find{|c| c.referenceName == "Microsoft.FeatureCategory"}.workItemTypes.map{|wit| wit.name} rescue []
    requirement_types = categories.find{|c| c.referenceName == "Microsoft.RequirementCategory"}.workItemTypes.map{|wit| wit.name} rescue []
    feature_hash = Hashie::Mash.new
    feature_types.each do |wit_name|
      wit = workitemtypes.find{|wit| wit.name == wit_name }
      feature_hash[wit_name] = Hashie::Mash.new({ :name => wit_name, :statuses => wit.transitions.map{|k,v| k}.reject{|s| s == ""}.sort() })
    end
    requirement_hash = Hashie::Mash.new
    requirement_types.each do |wit_name|
      wit = workitemtypes.find{|wit| wit.name == wit_name }
      requirement_hash[wit_name] = Hashie::Mash.new({ :name => wit_name, :statuses => wit.transitions.map{|k,v| k}.reject{|s| s == ""}.sort() })
    end
    Hashie::Mash.new({
      :feature_mappings => feature_hash,
      :requirement_mappings => requirement_hash
    })
  end

  def allowed_types_from_categories categories
    categories.map{|c| c.workItemTypes.map{|wit| wit.name} }.flatten().uniq()
  end
end
