class AhaServices::GitlabIssues < AhaService
    title 'GitLab Issues'
    caption 'Send features to GitLab Issues'

    #string :username
    #password :password
    password :private_token
    string :server_url, description: 'If you are using your own GitLab server please enter your server URL without a trailing slash (https://example.com/api/v3). If you are using gitlab.com leave this field empty.',
                        label: 'Server URL'
    install_button
    select :repository, collection: -> (meta_data, _data) do
        return [] if meta_data.nil? || meta_data.repos.nil?
        meta_data.repos.sort_by(&:name).collect { |repo| [repo.full_name, repo.full_name] }
    end

    select :mapping, collection: [
        ['Feature -> Issue, Requirement -> Issue', 'issue-issue'],
        ['Feature -> Issue, Requirement -> Checklist item', 'issue-checklist']
    ], description: 'Choose how features and requirements in Aha! will map to issues and checklists in GitLab.'

    # it looks like the GitHub status_mapping is not available to us, right now we'll need to assume the statuses
    # that we want: Open -> Ready To Develop, closed -> Ready to Ship
    # internal :status_mapping

    boolean :add_status_labels, description: 'Sync the Aha! status using a label on the GitLab issue'

    callback_url description: 'Use this URL to setup a two-way integration with GitLab issues.'

    def receive_installed
        meta_data.repos = repo_resource.all.map { |repo| { full_name: repo['name'] } }
    end

    def server_url
        if data.server_url.present?
            data.server_url
        else
            'https://www.gitlab.com/api/v3/'
        end
    end

    def receive_create_feature
      milestone = find_or_attach_gitlab_milestone(payload.feature.release)
      find_or_attach_gitlab_issue(payload.feature, milestone)
      update_requirements(payload.feature.requirements, milestone)
    end

    def receive_create_release
      find_or_attach_gitlab_milestone(payload.release)
    end

    def receive_update_feature
      milestone = find_or_attach_gitlab_milestone(payload.feature.release)
      update_or_attach_gitlab_issue(payload.feature, milestone)
      update_requirements(payload.feature.requirements, milestone)
    end

    def receive_update_release
      update_or_attach_gitlab_milestone(payload.release)
    end

    def receive_webhook
    end

    def find_or_attach_gitlab_milestone(release)
      if milestone = existing_milestone_integrated_with(release)
        milestone
      else
        attach_milestone_to(release)
      end
    end

    def update_or_attach_gitlab_milestone(release)
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
      integrate_release_with_gitlab_milestone(release, milestone)
      milestone
    end

    def create_milestone_for(release)
      milestone_resource.create title: release.name,
        description: "Created from Aha! #{release.url}",
        due_date: release.release_date.try(:to_time).try(:iso8601),
        state_event: release.released ? "closed" : "activate"
    end

    def update_milestone(number, release)
      milestone_resource.update number, title: release.name,
        due_date: release.release_date.try(:to_time).try(:iso8601),
        state_event: release.released ? "closed" : "activate"
    end

    def update_requirements(requirements, milestone)
      if (requirements) and !requirements_to_checklist?
        requirements.each do |requirement|
          update_or_attach_gitlab_issue(requirement, milestone)
        end
      end
    end

    def find_or_attach_gitlab_issue(resource, milestone)
      if issue = existing_issue_integrated_with(resource, milestone)
        issue
      else
        attach_issue_to(resource, milestone)
      end
    end

    def update_or_attach_gitlab_issue(resource, milestone)
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
      integrate_resource_with_gitlab_issue(resource, issue)
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
        .tap { |issue| update_issue_status(issue, resource)}
    end

    def update_labels(issue, resource)
      return if resource.tags.nil?
      tags = resource.tags.dup
      if add_status_labels_enabled?
        # remove that old aha statuses
        tags = tags.delete_if {|val| val.starts_with? "Aha!:"}
        # add a label for the status only if add_status_labels
        tags.push("Aha!:" + resource.workflow_status.name) unless resource.nil? or resource.workflow_status.nil?
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
      issue_body_parts.join("\n\n")
    end

    # TODO: Look into this for GitLab
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
        @repo_resource ||= GitlabRepoResource.new(self)
    end

    def milestone_resource
      @milestone_resource ||= GitlabMilestoneResource.new(self)
    end

    def server_display_url
        if data.server_url.present?
            data.server_url.gsub(/api\/v\d\/?/, '')
        else
            'https://gitlab.com'
        end
    end

    def integrate_release_with_gitlab_milestone(release, milestone)
      api.create_integration_fields("releases", release.reference_num, data.integration_id,
        {number: milestone['id'], url: "#{server_display_url}/projects/#{data.repository}/issues?milestone=#{milestone['title']}"})
    end
end
