require 'erb'

class MSTFSWorkItemResource < MSTFSResource

  PATCH_HEADER = { 'Content-Type'=> 'application/json-patch+json' }

  def create project, type, fields, links = []
    prepare_request
    body = (to_field_patch_array(fields) + to_relation_patch_array(links) ).to_json
    url = mstfs_project_url project, "wit/workitems/$" + ERB::Util.url_encode(type) 
    response = http_patch url, body, PATCH_HEADER
    return parsed_body(response) if response.status == 200
    # Something went wrong ..
    raise "Workitem creation unsuccessful"
  end

  def create_feature project, title, description
    create project, "Feature", Hash[
      "System.Title" => title,
      "System.Description" => description,
    ]
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
end
