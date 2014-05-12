class RedmineIssueResource < RedmineResource

  def create(payload_fragment: nil, parent_id: nil, attachments: nil)
    params = parse_payload \
      payload_fragment: payload_fragment,
      parent_id: parent_id,
      attachments: attachments
    prepare_request
    logger.debug("PARAMS: #{params.to_json}")
    response = http_post redmine_issues_path, params.to_json
    parse_response response, payload_fragment, parent_id
  end

  def update(payload_fragment: nil, parent_id: nil, attachments: nil)
    Rails.logger.debug("FRAGMENT: #{payload_fragment.inspect}")
    params = parse_payload \
      payload_fragment: payload_fragment,
      parent_id: parent_id,
      attachments: attachments
    issue_id = get_integration_field payload_fragment.integration_fields, 'id'

    prepare_request
    response = http_put redmine_issues_path(issue_id), params.to_json
    process_response response, 200 do
      logger.info("Updated feature #{issue_id}")
    end
  end

private

  def redmine_issues_path *concat
    str = "#{@service.data.redmine_url}/issues"
    str = str + '/' + concat.join('/') unless concat.empty?
    str + '.json'
  end

  def parse_payload(payload_fragment: nil, parent_id: nil, attachments: nil)
    payload_fragment ||= @payload.feature
    version_id = get_integration_field payload_fragment.release.try(:integration_fields), 'id'
    hashie = Hashie::Mash.new( issue: {
      tracker_id: @service.data.tracker,
      project_id: @service.data.project,
      subject: @service.resource_name(payload_fragment),
      parent_issue_id: parent_id,
      fixed_version_id: version_id,
      priority_id: @service.data.issue_priority
      }.reject {|k,v| v.nil?} )
    hashie.issue.merge!({ uploads: attachments.map {|a|
      {
        token: a.token,
        filename: a.file_name,
        content_type: a.content_type
      }}}) if attachments.present?
    hashie
  end

  def parse_response response, payload_fragment=nil, requirement=false
    payload_fragment ||= @payload.feature
    resource = requirement ? 'requirements' : 'features'
    process_response response, 201 do |body|
      create_integrations resource, payload_fragment.reference_num,
        {id: body.issue.id, url: "#{@service.data.redmine_url}/issues/#{body.issue.id}"}
      return body
    end
  end

end
