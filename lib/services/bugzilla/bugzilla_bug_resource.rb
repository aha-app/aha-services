class BugzillaBugResource < BugzillaResource

  def create_from_feature feature
    payload = feature_to_bug(feature)
    bug = create payload
    api.create_integration_fields("features", feature.reference_num, @service.data.integration_id, {id: bug.id, url: bug_url(bug.id)})
    (feature.attachments | feature.description.attachments).each {|a| attachment_resource.create bug.id, a }
  end

  private

  def bug_url id
    "#{service.data.server_url}/show_bug.cgi?id=#{id}"
  end
  
  def create bug
    url = bugzilla_url("bug")
    response = http_post url, bug.to_json
    process_response response
  end

  def feature_to_bug feature
    {
      :product => get_product().name,
      :component => get_component().name,
      :summary => feature.name,
      :description => html_to_markdown(feature.description.body),
      :version => "unspecified",
      :op_sys => "All",
      :platform => "All",
      :priority => "P1",
      :severity => "normal"
    }
  end

  def attachment_resource
    @attachment_resource ||= BugzillaAttachmentResource.new self.service
  end
end
