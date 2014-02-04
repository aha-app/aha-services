class AhaServices::GithubIssues < AhaService
  def receive_installed
    meta_data.repos = repo_resource.all
  end

  def receive_create_feature
    milestone = find_or_attach_github_milestone(payload.feature.release)
    find_or_attach_github_issue(payload.feature, milestone)
  end

  def receive_create_release
    find_or_attach_github_milestone(payload.release)
  end

  def receive_update_feature
    milestone = find_or_attach_github_milestone(payload.feature.release)
    update_or_attach_github_issue(payload.feature, milestone)
  end

  def receive_update_release
    update_or_attach_github_milestone(payload.release)
  end

  def find_or_attach_github_milestone(release)
    if milestone = existing_milestone_integrated_with(release)
      milestone
    else
      attach_milestone_to(release)
    end
  end

  def update_or_attach_github_milestone(release)
    if milestone_number = get_integration_field(release.integration_fields, 'number')
      update_milestone(milestone_number, release)
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

  def update_milestone(number, release)
    milestone_resource.update number, title: release.name,
                                      due_on: release.release_date,
                                      state: release.released ? "closed" : "open"
  end

  def find_or_attach_github_issue(resource, milestone)
    if issue = existing_issue_integrated_with(resource, milestone)
      issue
    else
      attach_issue_to(resource, milestone)
    end
  end

  def update_or_attach_github_issue(resource, milestone)
    if issue_number = get_integration_field(resource.integration_fields, 'number')
      update_issue(issue_number, resource)
    else
      attach_issue_to(resource, milestone)
    end
  end

  def existing_issue_integrated_with(resource, milestone)
    if issue_number = get_integration_field(resource.integration_fields, 'number')
      issue_resource.find_by_number_and_milestone(issue_number, milestone)
    end
  end

  def attach_issue_to(resource, milestone)
    issue = create_issue_for(resource, milestone)
    integrate_resource_with_github_issue(resource, issue)
    issue
  end

  def create_issue_for(resource, milestone)
    issue_resource
      .create(title: resource.name,
              body: resource.description.body,
              milestone: milestone['number'])
      .tap { |issue| update_labels(issue, resource) }
  end

  def update_issue(number, resource)
    issue_resource
      .update(number, title: resource.name,
                      body: resource.description.body)
      .tap { |issue| update_labels(issue, resource) }
  end

  def update_labels(issue, resource)
    label_resource.update(issue['number'], resource.tags)
  end

protected

  def repo_resource
    @repo_resource ||= GithubRepoResource.new(self)
  end

  def milestone_resource
    @milestone_resource ||= GithubMilestoneResource.new(self)
  end

  def issue_resource
    @issue_resource ||= GithubIssueResource.new(self)
  end

  def label_resource
    @label_resource ||= GithubLabelResource.new(self)
  end

  def integrate_release_with_github_milestone(release, milestone)
    api.create_integration_field(release.reference_num, self.class.service_name, :number, milestone['number'])
  end

  def integrate_resource_with_github_issue(resource, issue)
    api.create_integration_field(resource.reference_num, self.class.service_name, :number, issue['number'])
  end

  def get_integration_field(integration_fields, field_name)
    return nil if integration_fields.nil?
    field = integration_fields.detect do |f|
      f.service_name == self.class.service_name and f.name == field_name
    end
    field && field.value
  end

end
