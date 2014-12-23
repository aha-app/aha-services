class AhaServices::BitbucketIssues < AhaService
  title "Bitbucket Issues"
  caption "Send features to Bitbucket Issues"

  string :username
  password :password
  install_button
  select :repository, collection: -> (meta_data, data) do
    meta_data.repos.sort_by(&:name).collect { |repo| [repo.name, repo.slug] }
  end

  def receive_installed
    meta_data.repos = repo_resource.all.map do |repo|
      {
        slug: "#{repo['owner']}/#{repo['slug']}",
        name: "#{repo['owner']} / #{repo['name']}"
      }
    end
  end

  def receive_create_feature
    milestone = find_or_attach_bitbucket_milestone(payload.feature.release)
    find_or_attach_bitbucket_issue(payload.feature, milestone)
    update_requirements(payload.feature.requirements, milestone)
  end

  def receive_create_release
    find_or_attach_bitbucket_milestone(payload.release)
  end

  def receive_update_feature
    milestone = find_or_attach_bitbucket_milestone(payload.feature.release)
    update_or_attach_bitbucket_issue(payload.feature, milestone)
    update_requirements(payload.feature.requirements, milestone)
  end

  def receive_update_release
    update_or_attach_bitbucket_milestone(payload.release)
  end

  def find_or_attach_bitbucket_milestone(release)
    if milestone = existing_milestone_integrated_with(release)
      milestone
    else
      attach_milestone_to(release)
    end
  end

  def update_or_attach_bitbucket_milestone(release)
    if milestone_id = get_integration_field(release.integration_fields, 'id')
      update_milestone(milestone_id, release)
    else
      attach_milestone_to(release)
    end
  end

  def existing_milestone_integrated_with(release)
    if milestone_id = get_integration_field(release.integration_fields, 'id')
      milestone_resource.find_by_id(milestone_id)
    end
  end

  def attach_milestone_to(release)
    unless milestone = milestone_resource.find_by_name(release.name)
      milestone = create_milestone_for(release)
    end
    integrate_release_with_bitbucket_milestone(release, milestone)
    milestone
  end

  def create_milestone_for(release)
    milestone_resource.create name: release.name
  end

  def update_milestone(id, release)
    milestone_resource.update id, name: release.name
  end

  def update_requirements(requirements, milestone)
    if (requirements)
      requirements.each do |requirement|
        update_or_attach_bitbucket_issue(requirement, milestone)
      end
    end
  end

  def find_or_attach_bitbucket_issue(resource, milestone)
    if issue = existing_issue_integrated_with(resource, milestone)
      issue
    else
      attach_issue_to(resource, milestone)
    end
  end

  def update_or_attach_bitbucket_issue(resource, milestone)
    if issue_id = get_integration_field(resource.integration_fields, 'id')
      update_issue(issue_id, resource)
    else
      attach_issue_to(resource, milestone)
    end
  end

  def existing_issue_integrated_with(resource, milestone)
    if issue_id = get_integration_field(resource.integration_fields, 'id')
      issue_resource.find_by_id_and_milestone(issue_id, milestone)
    end
  end

  def attach_issue_to(resource, milestone)
    issue = create_issue_for(resource, milestone)
    integrate_resource_with_bitbucket_issue(resource, issue)
    issue
  end

  def create_issue_for(resource, milestone)
    issue_resource.create(title: resource_name(resource),
                          content: issue_body(resource.description),
                          milestone: milestone['name'])
  end

  def update_issue(id, resource)
    issue_resource .update(id, title: resource_name(resource),
                               content: issue_body(resource.description))
  end

  def issue_body(description)
    issue_body_parts = []
    issue_body_parts << html_to_markdown(description.body, true) if description.body.present?
    if description.attachments.present?
      issue_body_parts << attachments_in_body(description.attachments)
    end
    issue_body_parts.join("\n\n")
  end

  def attachments_in_body(attachments)
    attachments.map do |attachment|
      "![#{attachment.file_name}](#{attachment.download_url})"
    end.join("\n")
  end

protected

  def repo_resource
    @repo_resource ||= BitbucketRepoResource.new(self)
  end

  def milestone_resource
    @milestone_resource ||= BitbucketMilestoneResource.new(self)
  end

  def issue_resource
    @issue_resource ||= BitbucketIssueResource.new(self)
  end

  def integrate_release_with_bitbucket_milestone(release, milestone)
    api.create_integration_fields("releases", release.reference_num, data.integration_id,
      {id: milestone['id'], name: milestone["name"], url: "https://bitbucket.org/#{data.repository}/issues?#{milestone['name'].to_query('milestone')}"})
  end

  def integrate_resource_with_bitbucket_issue(resource, issue)
    api.create_integration_fields(reference_num_to_resource_type(resource.reference_num), resource.reference_num, data.integration_id,
      {id: issue['local_id'], url: "https://bitbucket.org/#{data.repository}/issue/#{issue['local_id']}"})
  end

end
