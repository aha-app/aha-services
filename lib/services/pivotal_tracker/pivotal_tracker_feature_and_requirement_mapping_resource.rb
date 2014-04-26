class PivotalTrackerFeatureAndRequirementMappingResource < PivotalTrackerProjectDependentResource

  def create_feature(feature)
    feature_mapping = feature_mapping_resource.create_from_feature(feature)
    feature.requirements.each do |requirement|
      requirement_mapping_resource.create_from_requirement(requirement, feature, feature_mapping)
    end
  end

  def update_feature(feature)
    feature_mapping = get_resource(feature.integration_fields)
    feature_mapping_resource.update_from_feature(feature_mapping, feature)

    # Create or update each requirement.
    feature.requirements.each do |requirement|
      requirement_mapping = get_resource(requirement.integration_fields)
      if requirement_mapping
        requirement_mapping_resource.update_from_requirement(requirement_mapping, requirement, feature_mapping)
      else
        requirement_mapping_resource.create_from_requirement(requirement, feature, feature_mapping)
      end
    end
  end

private

  def feature_mapping_resource
    @feature_mapping_resource ||= (mapping == 2) ?
      PivotalTrackerEpicResource.new(@service, project_id) :
      PivotalTrackerStoryResource.new(@service, project_id)
  end

  def requirement_mapping_resource
    @requirement_mapping_resource ||= (mapping == 3) ?
      PivotalTrackerTaskResource.new(@service, project_id) :
      PivotalTrackerStoryResource.new(@service, project_id)
  end

  def mapping
    @service.data.mapping
  end
end
