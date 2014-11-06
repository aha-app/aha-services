require 'erb'

class MSTFSWorkItemResource < MSTFSResource

  PATCH_HEADER = { 'Content-Type'=> 'application/json-patch+json' }

  def by_url url
    response = http_get url
    return parsed_body response if response.status == 200
    raise "Workitem not found"
  end

  def by_id id
    url = mstfs_url "wit/workitems/#{id}"
    by_url url
  end

  def create project, type, fields, links = []
    body = (to_field_patch_array(fields) + to_relation_patch_array(links) ).to_json
    url = mstfs_project_url project, "wit/workitems/$" + ERB::Util.url_encode(type)
    logger.debug "Sending request to #{url}\nBody: #{body}\n"
    response = http_patch url, body, PATCH_HEADER
    return parsed_body(response) if response.status == 200
    # Something went wrong ..
    raise AhaService::RemoteError.new "Workitem creation unsuccessfull, HTTP status #{response.status}"
  end

  def add_attachment workitem, attachment
    patch_set = [{
      :op => :add,
      :path => "/relations/-",
      :value => {
        :rel => :AttachedFile,
        :url => attachment.url
      }
    }]
    update workitem.id, patch_set
  end

  def update workitem_id, patch_set
    return if patch_set.length == 0
    body = patch_set.to_json
    url = mstfs_url "wit/workitems/#{workitem_id}"
    response = http_patch url, body, PATCH_HEADER
    return parsed_body response if response.status == 200
    raise AhaService::RemoteError.new("Could not update workitem, response status is #{response.status}")
  end

protected
  def to_field_patch_array fields
    fields.collect do |path, value|
      {
        op: "add",
        path: "/fields/" + path,
        value: value
      }
    end
  end

  def to_relation_patch_array relations
    relations.collect do |relation|
      {
        op: "add",
        path: "/relations/-",
        value: {
          rel: relation[:rel],
          url: relation[:url]
        }
      }
    end
  end

  def attachment_resource
    @attachment_resource ||= MSTFSAttachmentResource.new(@service)
  end
end
