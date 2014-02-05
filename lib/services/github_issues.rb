class AhaServices::GithubIssues < AhaService
  string :username
  password :password
  install_button
  select :repository, collection: -> (meta_data) do
    meta_data.repos.sort_by(&:name).collect { |repo| [repo.name, repo.name] }
  end

  def receive_installed
    meta_data.repos = repo_resource.all.map { |repo| { name: repo.name } }
  end

  def receive_create_feature
    milestone = find_or_attach_github_milestone(payload.feature.release)
    find_or_attach_github_issue(payload.feature, milestone)
    update_requirements(payload.feature.requirements, milestone)
  end

  def receive_create_release
    find_or_attach_github_milestone(payload.release)
  end

  def receive_update_feature
    milestone = find_or_attach_github_milestone(payload.feature.release)
    update_or_attach_github_issue(payload.feature, milestone)
    update_requirements(payload.feature.requirements, milestone)
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

  def update_requirements(requirements, milestone)
    if (requirements)
      requirements.each do |requirement|
        update_or_attach_github_issue(requirement, milestone)
      end
    end
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
      .create(title: resource_name(resource),
              body: issue_body(resource.description),
              milestone: milestone['number'])
      .tap { |issue| update_labels(issue, resource) }
  end

  def update_issue(number, resource)
    issue_resource
      .update(number, title: resource_name(resource),
                      body: issue_body(resource.description))
      .tap { |issue| update_labels(issue, resource) }
  end

  def update_labels(issue, resource)
    label_resource.update(issue['number'], resource.tags)
  end

  # Used for features (which are required to have a name)
  # and for requirements (which don't have a name)
  def resource_name(resource)
    resource.name || description_to_title(resource.description.body)
  end

  def issue_body(description)
    issue_body_parts = []
    issue_body_parts << description.body if description.body.present?
    if description.attachments.present?
      issue_body_parts << attachments_in_body(description.attachments)
    end
    issue_body_parts.join("\n\n")
  end

  def attachments_in_body(attachments)
    attachments.map do |attachment|
      "#{attachment.file_name} (#{attachment.download_url})"
    end.join("\n")
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
    api.create_integration_field(resource.reference_num, self.class.service_name, :url, "https://github.com/#{data.username}/#{data.repo}/issues?milestone=#{milestone['number']}")
  end

  def integrate_resource_with_github_issue(resource, issue)
    api.create_integration_field(resource.reference_num, self.class.service_name, :number, issue['number'])
    api.create_integration_field(resource.reference_num, self.class.service_name, :url, "https://github.com/#{data.username}/#{data.repo}/issues/#{issue['number']}")
  end

  def get_integration_field(integration_fields, field_name)
    return nil if integration_fields.nil?
    field = integration_fields.detect do |f|
      f.service_name == self.class.service_name and f.name == field_name
    end
    field && field.value
  end

end
