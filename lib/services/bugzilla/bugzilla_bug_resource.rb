class BugzillaBugResource < BugzillaResource

  def create_from_feature feature
    payload = feature_to_bug(feature)
    bug = create payload
    api.create_integration_fields("features", feature.reference_num, @service.data.integration_id, {id: bug.id, url: bug_url(bug.id)})
    (feature.attachments | feature.description.attachments).each {|a| attachment_resource.create bug.id, a }
    # create bugs for requirements
    requirement_bugs = feature.requirements.map {|r| create_from_requirement r }
    # collect their ids
    ids = requirement_bugs.map {|b| b.id }
    # make the "feature" bug depend on them
    update bug.id, { :depends_on => { :set => ids } }
    bug
  end

  def update_from_feature feature
    bug_id = integration_field_id feature
    payload = feature_to_bug(feature)
    bug = update bug_id, payload
    update_attachments bug_id, (feature.attachments | feature.description.attachments)
    bug
  end

  def create_from_requirement requirement
    payload = requirement_to_bug(requirement)
    bug = create payload
    api.create_integration_fields("requirements", requirement.reference_num, @service.data.integration_id, {id: bug.id, url: bug_url(bug.id)})
    (requirement.attachments | requirement.description.attachments).each {|a| attachment_resource.create bug.id, a }
    bug
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

  def update id, bug
    url = bugzilla_url "bug/#{id}"
    response = http_put url, bug.to_json
    process_response response
  end

  def update_attachments bug_id, aha_attachments
    url = bugzilla_url "bug/#{bug_id}/attachment?exclude_fields=data"
    bz_attachments = process_response(http_get(url)).bugs[bug_id.to_s]
    aha_attachments.each do |aha_a|
      bz_a = bz_attachments.find{|e| e.file_name == aha_a.file_name }
      if bz_a and bz_a[:size] != aha_a.file_size then
        # TODO: updating an attachment currently fails in Bugzilla
        #attachment_resource.update bz_a.id, aha_a
      elsif bz_a.nil?
        attachment_resource.create bug_id, aha_a
      end
    end
  end
  
  def feature_to_bug feature
    common_bug_fields.merge({
      :summary => feature.name,
      :description => html_to_markdown(feature.description.body)
    })
  end

  def requirement_to_bug requirement
    common_bug_fields.merge({
      :summary => requirement.name,
      :description => html_to_markdown(requirement.description.body),
    })
  end

  def common_bug_fields
    {
      :product => get_product().name,
      :component => get_component().name,
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
