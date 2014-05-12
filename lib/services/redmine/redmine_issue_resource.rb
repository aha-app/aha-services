require 'clothred'

class RedmineIssueResource < RedmineResource
  
  def create(payload_fragment: nil, parent_id: nil)
    params = parse_payload \
      payload_fragment: payload_fragment,
      parent_id: parent_id,
      attachments: check_attachments(payload_fragment)
    prepare_request
    logger.debug("PARAMS: #{params.to_json}")
    response = http_post redmine_issues_path, params.to_json
    response_body = parse_response response, payload_fragment, parent_id
    {id: response_body[:issue][:id]}
  end

  def update(payload_fragment: nil, parent_id: nil)
    issue_id = get_integration_field payload_fragment.integration_fields, 'id'
    params = parse_payload \
      payload_fragment: payload_fragment,
      parent_id: parent_id,
      attachments: check_attachments(payload_fragment, issue_id)
    prepare_request
    response = http_put redmine_issues_path(issue_id), params.to_json
    process_response response, 200 do
      logger.info("Updated feature #{issue_id}")
    end
    
    {id: issue_id}
  end

private

  def attachment_resource
    @attachment_resource ||= RedmineUploadResource.new(@service)
  end

  def check_attachments(resource, issue_id = nil)
    attachments = resource.attachments.dup | resource.description.attachments.dup
    if issue_id
      attachment_resource.all_for_issue(issue_id).each do |redmine_attachment|
        attachments.reject! do |aha_attachment|
          attachments_match(aha_attachment, redmine_attachment)
        end
      end
    end
    attachments.map do |attachment|
      attachment.merge(token: attachment_resource.upload_attachment(attachment))
    end
  end
  
  def attachments_match(aha_attachment, redmine_attachment)
    aha_attachment.file_name == redmine_attachment.filename and
      aha_attachment.file_size.to_i == redmine_attachment.filesize.to_i
  end
  
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
      description: ClothRed.new(payload_fragment.description.body).to_textile,
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
