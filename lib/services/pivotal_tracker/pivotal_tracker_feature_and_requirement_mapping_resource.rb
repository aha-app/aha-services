class PivotalTrackerFeatureAndRequirementMappingResource < PivotalTrackerProjectDependentResource

  def create_feature(feature)
    if initiative_mapping_resource
      initiative_mapping = initiative_mapping_resource.find_or_create_from_initiative(feature.initiative)
    else
      initiative_mapping = nil
    end
    feature_mapping = feature_mapping_resource.create_from_feature(feature, initiative_mapping)
    feature.requirements.each do |requirement|
      requirement_mapping_resource.create_from_requirement(requirement, feature, feature_mapping)
    end
  end

  def update_feature(feature)
    if initiative_mapping_resource
      initiative_mapping = initiative_mapping_resource.find_or_create_from_initiative(feature.initiative)
    else
      initiative_mapping = nil
    end
    feature_mapping = get_resource(feature.integration_fields)
    feature_mapping_resource.update_from_feature(feature_mapping, feature, initiative_mapping)

    # Create or update each requirement.
    feature.requirements.each do |requirement|
      requirement_mapping = get_resource(requirement.integration_fields)
      if requirement_mapping.present?
        requirement_mapping_resource.update_from_requirement(requirement_mapping, requirement, feature_mapping)
      else
        requirement_mapping_resource.create_from_requirement(requirement, feature, feature_mapping)
      end
    end
  end

private

  def initiative_mapping_resource
    @initiative_mapping_resource ||= (mapping == "epic-story-task") ?
      PivotalTrackerEpicResource.new(@service, project_id) :
      nil
  end

  def feature_mapping_resource
    @feature_mapping_resource ||= (mapping == "epic-story") ?
      PivotalTrackerEpicResource.new(@service, project_id) :
      PivotalTrackerStoryResource.new(@service, project_id)
  end

  def requirement_mapping_resource
    @requirement_mapping_resource ||= (mapping == "story-task" || mapping == "epic-story-task") ?
      PivotalTrackerTaskResource.new(@service, project_id) :
      PivotalTrackerStoryResource.new(@service, project_id)
  end

  def mapping
    @service.data.mapping
  end
end
