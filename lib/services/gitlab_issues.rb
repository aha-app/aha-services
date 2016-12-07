class AhaServices::GitlabIssues < AhaService
    title 'GitLab Issues'
    caption 'Send features to GitLab Issues'

    string :username
    password :password
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
        meta_data.repos = repo_resource.all.map { |repo| { full_name: repo['full_name'] } }
    end

    def receive_webhook
        nil
    end

    def server_url
        if data.server_url.present?
            data.server_url
        else
            'https://www.gitlab.com/api/v3/'
        end
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
end
