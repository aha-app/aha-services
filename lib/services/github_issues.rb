class AhaServices::GithubIssues < AhaService
  def receive_installed
    meta_data.repos = repo_resource.all
  end

  def receive_create_feature
    milestone = find_or_attach_github_milestone(payload.feature.release)
  end

  def receive_create_release
    find_or_attach_github_milestone(payload.release)
  end

  def find_or_attach_github_milestone(release)
    if milestone = existing_milestone_integrated_with(release)
      milestone
    else
      attach_milestone_to(release)
    end
  end

  def existing_milestone_integrated_with(release)
    if milestone_number = get_integration_field(release.integration_fields, 'number')
      milestone_resource.find_by_number(milestone_number)
    end
  end

  def attach_milestone_to(release)
    unless milestone = milestone_resource.find_by_title(release.name)
      milestone = create_milestone_for(release)
    end
    integrate_release_with_github_milestone(release, milestone)
    milestone
  end

  def create_milestone_for(release)
    milestone_resource.create title: release.name,
                              description: "Created from Aha! #{release.url}",
                              due_on: release.release_date,
                              state: release.released ? "closed" : "open"
  end

protected

  def repo_resource
    @repo_resource ||= GithubRepoResource.new(self)
  end

  def milestone_resource
    @milestone_resource ||= GithubMilestoneResource.new(self)
  end

  def integrate_release_with_github_milestone(release, milestone)
    api.create_integration_field(release.reference_num, self.class.service_name, :number, milestone['number'])
  end

  def get_integration_field(integration_fields, field_name)
    return nil if integration_fields.nil?
    field = integration_fields.detect do |f|
      f.service_name == self.class.service_name and f.name == field_name
    end
    field && field.value
  end

end
