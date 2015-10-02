class BugzillaBugResource < BugzillaResource

  def create_from_feature feature
    payload = to_bug(feature)
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
    payload = to_bug_update(feature)
    bug = update bug_id, payload
    update_attachments bug_id, (feature.attachments | feature.description.attachments)
    new_blockers = upsert_requirements feature.requirements
    update bug_id, { :depends_on => { :add => new_blockers } } if new_blockers.size > 0
    bug
  end

  def create_from_requirement requirement
    payload = to_bug(requirement)
    bug = create payload
    api.create_integration_fields("requirements", requirement.reference_num, @service.data.integration_id, {id: bug.id, url: bug_url(bug.id)})
    (requirement.attachments | requirement.description.attachments).each {|a| attachment_resource.create bug.id, a }
    bug
  end

  def update_from_requirement requirement
    bug_id = integration_field_id(requirement)
    payload = to_bug_update(requirement)
    bug = update bug_id, payload
    update_attachments bug_id, (requirement.attachments | requirement.description.attachments)
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

  # Update or create new bugs for all requirements
  # returns the ids of newly created bugs
  def upsert_requirements requirements
    ids = []
    requirements.each do |requirement|
      bug_id = integration_field_id requirement
      if bug_id.nil? then
        bug = create_from_requirement requirement
        ids << bug.id
      else
        update_from_requirement requirement
      end
    end
    ids
  end
  
  def to_bug resource
    common_bug_fields.merge({
      :summary => resource.name,
      :description => html_to_markdown(resource.description.body)
    })
  end

  def to_bug_update resource
    common_bug_fields.merge({
      :summary => resource.name,
      # This will create a new comment but not update the description
      #:comment => {
      #  :body => html_to_markdown(resource.description.body),
      #  :is_markdown => true
      #}
    })
  end

  def common_bug_fields
    defaults = 
      if @service.meta_data && @service.meta_data.defaults
        @service.meta_data.defaults[get_product().name]
      else
        {}
      end
    defaults.merge({
      :product => get_product().name,
      :component => get_component().name,
    })
  end

  def attachment_resource
    @attachment_resource ||= BugzillaAttachmentResource.new self.service
  end
end
