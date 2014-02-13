class RedmineIssueResource < RedmineResource

  def create payload_fragment=nil, parent_id=nil
    params = parse_payload(payload_fragment || @payload.feature, parent_id)
    prepare_request
    response = http_post redmine_issues_path, params.to_json
    parse_response response, payload_fragment
  end

  def update
    params = parse_payload @payload.feature
    issue_id = get_integration_field @payload.feature.integration_fields, 'id'

    prepare_request
    response = http_put redmine_issues_path(issue_id), params.to_json
    process_response response, 201 do
      logger.info("Updated feature #{issue_id}")
    end
  end

private

  def redmine_issues_path *concat
    str = "#{@service.data.redmine_url}/projects/#{@service.data.project_id}/issues"
    str = str + '/' + concat.join('/') unless concat.empty?
    str + '.json'
  end

  def parse_payload payload_fragment, parent_id=nil
    version_id = get_integration_field @payload.feature.integration_fields, 'version_id'
    hashie = Hashie::Mash.new( issue: {
      tracker_id: kind_to_tracker_id(payload_fragment.kind),
      subject: payload_fragment.name })
    hashie[:issue].merge!(parent_issue_id: parent_id) if parent_id
    hashie[:issue].merge!(fixed_version_id: version_id) if version_id
    hashie
  end

  def parse_response response, payload_fragment=nil
    payload_fragment ||= @payload.feature
    process_response response, 201 do |body|
      create_integrations payload_fragment.reference_num,
        id: body.issue.id,
        name: body.issue.subject,
        url: redmine_issues_path(body.issue.id)
      if payload_fragment.release && body.issue.fixed_version
        create_integrations payload_fragment.release.reference_num,
          id: body.issue.fixed_version.id,
          name: body.issue.fixed_version.name,
          url: "#{@service.data.redmine_url}/version/#{body.issue.fixed_version.id}"
      end
      return body
    end
  end

  def kind_to_tracker_id kind
    case kind
    when "bug_fix"
      1 # bug tracker
    when "research"
      3 # support tracker
    else
      2 # feature tracker
    end
  end

end
