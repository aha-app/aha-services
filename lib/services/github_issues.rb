class AhaServices::GithubIssues < AhaService
  title "GitHub Issues"
  caption "Send features to GitHub Issues"

  string :username
  password :password
  string :server_url, description: "If you are using Github Enterprise enter your server URL without a trailing slash (https://example.com/api/v3). If you are using github.com leave this field empty.",
    label: "Server URL"
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

  boolean :add_status_labels, description: "Sync the Aha! status using a label on the Github issue"

  callback_url description: "Use this URL to setup a two-way integration with Github issues."

  def receive_installed
    meta_data.repos = repo_resource.all.map { |repo| { full_name: repo['full_name'] } }
  end

  def server_url
    if self.data.server_url.present?
      self.data.server_url
    else
      "https://api.github.com"
    end
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

  def add_status_labels_enabled?
    if data.add_status_labels.is_a?(TrueClass) || data.add_status_labels.is_a?(FalseClass)
      data.add_status_labels
    elsif data.add_status_labels.is_a?(String)
      !data.add_status_labels.to_i.zero?
    elsif data.add_status_labels.is_a?(Numeric)
      !data.add_status_labels.zero?
    else
      false
    end
  end

  def receive_webhook
    return unless payload.webhook
    action, issue, repo = payload.webhook.action, payload.webhook.issue, payload.webhook.repository
    return unless issue and action and repo
    return unless repo.full_name == data.repository
    
    results = api.search_integration_fields(data.integration_id, "number", issue.number)['records'] rescue []
    # only consider requirements or features. It is possible for a release to have
    # an issue number that matches a feature and a release - only consider the feature
    results = results.select {|result| result.requirement || result.feature }

    if results.size > 1
      logger.warn("Multiple entries returned for issue number '#{issue.number}' - none will be updated.")
      return
    elsif results.size == 0
      logger.warn("Issue '#{issue.number}' is not linked to a record in Aha! - skipping webhook")
      return
    end

    if resource = results[0].requirement then
      resource_kind = :requirement
    elsif resource = results[0].feature then
      resource_kind = :feature
    else
      return
    end

    label_tags = issue.labels.map(&:name) rescue []
    new_tags = label_tags.dup 
    aha_statuses = []

    # remove the aha_statuses as these are 'special' tags used to change the state
    if add_status_labels_enabled?
      aha_statuses = new_tags.select {|val| val.starts_with? "Aha!:"}
      new_tags.delete_if {|val| val.starts_with? "Aha!:"}
    end

    diff = {}
    diff[:name] = issue.title if resource.name != issue.title

    case action
    when "unlabeled"
      # add the label back to the issue if all aha labels were removed
      label_resource.update(issue.number, [new_tags, payload.label.name].flatten) if add_status_labels_enabled? && aha_statuses.empty? && payload.label.name.starts_with?("Aha!:")
    when "labeled"
      if add_status_labels_enabled? && !aha_statuses.nil? && !aha_statuses.empty?
        aha_status = aha_statuses.pop
        # if there are multiple aha_statuses then clear all except for the last status
        label_resource.update(issue.number, [new_tags, aha_status].flatten) unless aha_statuses.empty?
        # trim the Aha!: prefix to match the aha workflow_status name
        new_status = aha_status[5..-1]
        # update the status
        diff[:workflow_status] = new_status if !new_status.nil? && new_status != resource.workflow_status.name
      end
    when "closed", "reopened"
      diff = diff_status_change(resource, issue, diff)
    when "opened"
      if get_integration_field(resource.integration_fields, "sent_from_aha")
        # force issue status to match Aha! (since we can't control it on creation)
        update_issue_status(issue, resource)
      else
        # else update Aha! to match issue status
        diff = diff_status_change(resource, issue, diff)
      end
      
      if status = mapped_status(issue) && status == resource.workflow_status.id
        new_tags.push(workflow_status_to_github_label(resource.workflow_status.name))
        new_tags.push(*resource.tags)
      end
    end
    
    if sync_tags?(action, resource.tags, new_tags)
      diff[:tags] = new_tags
    end

    if diff.size > 0  then
      updated_resource = api.put(resource.resource, { resource_kind => diff })
      if add_status_labels_enabled? && %w(closed opened reopened).include?(action) && diff.key?(:workflow_status)
        # use current tags in open state when the workflow status changes
        if action == "opened"
          new_tags.push(*resource.tags)
          new_tags.uniq!
        end
        label_resource.update(issue.number, [new_tags, workflow_status_to_github_label(updated_resource[resource_kind].workflow_status.name)].flatten) 
      end
    end
  end
  
  def mapped_status(issue)
    data.status_mapping.to_h[issue.state]
  end
  
  def diff_status_change(resource, issue, diff)
    if status = mapped_status(issue) and status != resource.workflow_status.id
      diff[:workflow_status] = status
    end
    diff
  end

  def sync_tags?(action, resource_tags, new_tags)
    if Set.new(resource_tags) == Set.new(new_tags)
      return false
    end

    case action
    when "closed", "reopened", "unlabeled", "labeled"
      true
    else
      false
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
      due_on: release.release_date.try(:to_time).try(:iso8601),
      state: release.released ? "closed" : "open"
  end

  def update_milestone(number, release)
    milestone_resource.update number, title: release.name,
      due_on: release.release_date.try(:to_time).try(:iso8601),
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
      update_issue(issue_number, resource, milestone)
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
    api.create_integration_fields(
      reference_num_to_resource_type(resource.reference_num),
      resource.reference_num, 
      data.integration_id,
      "sent_from_aha" => true
    )
    issue_resource
      .create({
        title: resource_name(resource),
        body: issue_body(resource),
        milestone: milestone['number'],
        labels: resource&.tags&.dup || []# Send the normal tags immediately so we don't thrash them with a webhook
      }).tap { |issue| update_labels(issue, resource, true) }
  end

  def update_issue(number, resource, milestone)
    issue_resource
      .update(number, {
        title: resource_name(resource),
        body: issue_body(resource),
        milestone: milestone['number']
      })
      .tap { |issue| update_labels(issue, resource) }
      .tap { |issue| update_issue_status(issue, resource)}
  end

  def workflow_status_to_github_label(status)
    "Aha!:#{status}"
  end

  def update_labels(issue, resource, created = false)
    return if resource.tags.nil?
    tags = resource.tags.dup
    if add_status_labels_enabled?
      status_map = data.status_mapping.nil? ? nil : data.status_mapping[issue["state"]]
      # Do not send status on create. 
      if !created
        # remove that old aha statuses
        tags = tags.delete_if {|val| val.starts_with? "Aha!:"}
        # add a label for the status only if add_status_labels
        tags.push(workflow_status_to_github_label(resource.workflow_status.name)) unless resource.nil? or resource.workflow_status.nil?
      elsif status_map && resource.workflow_status.id == status_map
        # The workflow status change normally adds this label. If we are in the new state already
        # we need to send it now.
        tags.push(workflow_status_to_github_label(resource.workflow_status.name)) 
      end
    end
    label_resource.update(issue['number'], tags)
  end

  def update_issue_status(issue, resource)
    # close the issue if the aha_status matches the close status
    status = data.status_mapping.key(resource.workflow_status.id)
    if !status.nil? && status == 'closed'
      issue_resource.update(issue['number'], {state: status})
    end
  end

  def issue_body(resource)
    issue_body_parts = []
    if resource.description.body.present?
      body = html_to_markdown(resource.description.body, true)
      body = bugfix_escaping_in_method_name(body)
      issue_body_parts << body
    end
    issue_body_parts << requirements_to_checklist(resource) if resource.requirements.present? and requirements_to_checklist?
    if resource.description.attachments.present?
      issue_body_parts << attachments_in_body(resource.description.attachments)
    end
    issue_body_parts << "Created from Aha! #{resource.url}" if resource.respond_to?(:url)

    issue_body_parts.join("\n\n")
  end

  # Github's parser is smart enough to not treat _ or * inside of `` blocks as markdown control characters, so we don't need to escape them
  def bugfix_escaping_in_method_name body
    body = body.gsub(/`[^`]+`/) do |code_point|
      code_point.gsub('\\_', "_").gsub('\\*', "*")
    end
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

  def server_display_url
    if self.data.server_url.present?
      self.data.server_url.gsub(/api\/v\d\/?/, '')
    else
      "https://github.com"
    end
  end

  def github_url(paths, query = {})
    paths = [data.repository.split("/"), *paths.map{|path| path.to_s.split("/")}].flatten
    paths.reject!(&:empty?)
    server_slash = server_display_url =~ /\/\z/ ? "" : "/"
    url_string = server_display_url + server_slash + paths.join("/")
    url = URI.parse(url_string)
    if query.present?
      url.query = URI.encode_www_form(query)
    end
    url.to_s
  end

  def integrate_release_with_github_milestone(release, milestone)
    api.create_integration_fields("releases", release.reference_num, data.integration_id,
      {number: milestone['number'], url: github_url(["issues"], {"milestone"=>milestone['number']})})
  end

  def integrate_resource_with_github_issue(resource, issue)
    api.create_integration_fields(reference_num_to_resource_type(resource.reference_num), resource.reference_num, data.integration_id,
      {number: issue['number'], url: github_url(["issues", issue['number']])})
  end

  def requirements_to_checklist?
    data.mapping == "issue-checklist"
  end

  def requirements_to_checklist resource
    resource.requirements.map do |requirement|
      status = (requirement.workflow_status.try(:complete) || false) ? "x" : " "
      head = "- [#{status}] #{requirement.name}\n"
      body = html_to_markdown(requirement.description.body, true)
      body += attachments_in_body(requirement.description.attachments) if requirement.description.attachments.present?
      head + indent(body, "    ")
    end.join("\n").gsub(/\n+/m, "\n")
  end

  def indent text, prefix
    text.lines.map{|line| prefix + line.chomp }.join("\n")
  end
end
