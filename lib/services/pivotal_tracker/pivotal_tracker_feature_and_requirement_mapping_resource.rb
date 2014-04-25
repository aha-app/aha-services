class PivotalTrackerFeatureAndRequirementMappingResource < PivotalTrackerProjectDependentResource

  def create_feature(feature)
    feature_mapping_id = feature_mapping_resource.create_from_feature(feature).id
    feature.requirements.each do |requirement|
      requirement_mapping_resource.create_from_requirement(requirement, feature, feature_mapping_id)
    end
  end

  def update_feature(feature)
    feature_mapping_id = get_service_id(feature.integration_fields)
    feature_mapping_resource.update_from_feature(feature_mapping_id, feature)

    # Create or update each requirement.
    feature.requirements.each do |requirement|
      requirement_mapping_id = get_service_id(requirement.integration_fields)
      if requirement_mapping_id
        requirement_mapping_resource.update_from_requirement(requirement_mapping_id, requirement, feature_mapping_id)
      else
        requirement_mapping_resource.create_from_requirement(requirement, feature, feature_mapping_id)
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
    @requirement_mapping_resource ||= PivotalTrackerStoryResource.new(@service, project_id)
  end

  def mapping
    @service.data.mapping
  end
end
