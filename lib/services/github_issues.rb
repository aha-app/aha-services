class AhaServices::GithubIssues < AhaService
  title "GitHub Issues"
  caption "Send features to GitHub Issues"
  
  string :username
  password :password
  install_button
  select :repository, collection: -> (meta_data, data) do
    meta_data.repos.sort_by(&:name).collect { |repo| [repo.full_name, repo.full_name] }
  end

  select :mapping, collection: [
           ["Feature -> Issue, Requirement -> Issue","issue-issue"],
           ["Feature -> Issue, Requirement -> Checklist item", "issue-checklist"]
         ],
         description: "Choose how features and requirements in Aha! will map to issues and checklists in GitHub."

  internal :status_mapping

  callback_url description: "Use this URL to setup a two-way integration with Github issues."

  def receive_installed
    meta_data.repos = repo_resource.all.map { |repo| { full_name: repo['full_name'] } }
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

  def receive_webhook
    action = payload.webhook.action
    issue = payload.webhook.issue
    return unless issue and action
    results = api.search_integration_fields(data.integration_id, "number", issue.number)['records'] rescue []
    return unless results.size == 1
    if resource = results[0].requirement then
      resource_kind = :requirement
    elsif resource = results[0].feature then
      resource_kind = :feature
    else
      return
    end
    new_status = data.status_mapping.nil? ? nil : data.status_mapping[issue.state]
    new_tags = issue.labels.map{|l| l.name } rescue []
    diff = {}
    diff[:name] = issue.title if resource.name != issue.title
    diff[:workflow_status] = new_status if !new_status.nil? and new_status != resource.workflow_status.id
    diff[:tags] = new_tags if Set.new(resource.tags) != Set.new(new_tags)
    if diff.size > 0  then
      api.put resource.resource, { resource_kind => diff }
    end
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
    if (requirements) and !requirements_to_checklist?
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
              body: issue_body(resource),
              milestone: milestone['number'])
      .tap { |issue| update_labels(issue, resource) }
  end

  def update_issue(number, resource)
    issue_resource
      .update(number, title: resource_name(resource),
                      body: issue_body(resource))
      .tap { |issue| update_labels(issue, resource) }
  end

  def update_labels(issue, resource)
    label_resource.update(issue['number'], resource.tags)
  end

  def issue_body(resource)
    issue_body_parts = []
    issue_body_parts << html_to_markdown(resource.description.body, true) if resource.description.body.present?
    issue_body_parts << requirements_to_checklist(resource) if resource.requirements.present? and requirements_to_checklist?
    if resource.description.attachments.present?
      issue_body_parts << attachments_in_body(resource.description.attachments)
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
    api.create_integration_fields("releases", release.reference_num, data.integration_id, 
      {number: milestone['number'], url: "https://github.com/#{data.repository}/issues?milestone=#{milestone['number']}"})
  end

  def integrate_resource_with_github_issue(resource, issue)
    api.create_integration_fields(reference_num_to_resource_type(resource.reference_num), resource.reference_num, data.integration_id, 
      {number: issue['number'], url: "https://github.com/#{data.repository}/issues/#{issue['number']}"})
  end

  def requirements_to_checklist?
    data.mapping == "issue-checklist"
  end

  def requirements_to_checklist resource
    resource.requirements.map do |requirement|
      head = "- [ ] #{requirement.name}\n"
      body = html_to_markdown(requirement.description.body)
      body += attachments_in_body(requirement.description.attachments) if requirement.description.attachments.present?
      head + indent(body, "    ")
    end.join("\n\n")
  end

  def indent text, prefix
    text.lines.map{|line| prefix + line }.join("\n")
  end
end
