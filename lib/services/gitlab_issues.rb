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
    end

    def receive_create_release
      find_or_attach_gitlab_milestone(payload.release)
    end

    def receive_update_feature
    end

    def receive_update_release
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
        due_on: release.release_date.try(:to_time).try(:iso8601),
        state: release.released ? "closed" : "open"
    end

    def update_milestone(number, release)
      milestone_resource.update number, title: release.name,
        due_on: release.release_date.try(:to_time).try(:iso8601),
        state: release.released ? "closed" : "open"
    end

    protected

    def repo_resource
        @repo_resource ||= GitlabRepoResource.new(self)
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
        {number: milestone['number'], url: "#{server_display_url}/projects/#{data.repository}/issues?milestone=#{milestone['title']}"})
    end
end
