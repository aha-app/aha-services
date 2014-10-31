require 'erb'

class MSTFSWorkItemResource < MSTFSResource

  PATCH_HEADER = { 'Content-Type'=> 'application/json-patch+json' }

  def by_url url
    response = http_get url
    return parsed_body response if response.status == 200
    raise "Workitem not found"
  end

  def create project, type, fields, links = []
    body = (to_field_patch_array(fields) + to_relation_patch_array(links) ).to_json
    url = mstfs_project_url project, "wit/workitems/$" + ERB::Util.url_encode(type) 
    response = http_patch url, body, PATCH_HEADER
    return parsed_body(response) if response.status == 200
    # Something went wrong ..
    raise "Workitem creation unsuccessful"
  end

  def create_feature project, feature
    created_feature = create project, "Feature", Hash[
      "System.Title" => feature.name,
      "System.Description" => feature.description.body,
    ]
    api.create_integration_fields("features", feature.reference_num, @service.data.integration_id, {id: created_feature.id, url: created_feature.url})
    (feature.attachments | feature.description.attachments).each do |aha_attachment|
      new_attachment = attachment_resource.upload_attachment aha_attachment
      add_attachment created_feature, new_attachment
    end
    created_feature
  end

  def add_attachment workitem, attachment
    body = [{
      :op => :add,
      :path => "/relations/-",
      :value => {
        :rel => :AttachedFile,
        :url => attachment.url
      }
    }].to_json
    url = mstfs_url "wit/workitems/#{workitem.id}"
    response = http_patch url, body, PATCH_HEADER
    return parsed_body response if response.status == 200
    raise AhaService::RemoteError.new("Could not link attachment, response status is #{response.status}")
  end

  def update workitem_id, title, description
    body = [{
      :op => :replace,
      :path => "/fields/System.Title",
      :value => title
    }, {
      :op => :replace,
      :path => "/fields/System.Description",
      :value => description
    }].to_json
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
