require 'erb'

class P2PMWorkItemResource < P2PMResource

  PATCH_HEADER = { 'Content-Type'=> 'application/json-patch+json' }

  def by_url url
    response = http_get url
    process_response response
  end

  def by_id id
    url = mstfs_url "wit/workitems/#{id}?$expand=all"
    by_url url
  end

  def create table, body, security_token
    #body = (to_field_patch_array(fields) + to_relation_patch_array(links) ).to_json
    http.headers["Authorization"] = "Bearer " + security_token
    url = "http://52.39.212.230:8080/api/1.0/workflow/pmtable/" + table + "/data"
    #url = mstfs_project_url project, "wit/workitems/$" + ERB::Util.url_encode(type)
    logger.debug "Sending request to #{url}\nBody: #{body}\n"
    my_header = { :Authorization => 'Bearer ' + security_token}
    #response = http_patch url, body.to_json, my_header
    response = RestClient.post url, body.to_json, my_header { |response, request, result, &block|
      case response.code
        when 201
          p "It worked !"
          response
        when 423
          raise SomeCustomExceptionIfYouWant
        else
          response.return!(&block)
      end
    }
    process_response response
  end

  def add_attachment workitem, attachment, size
    return unless attachment.respond_to? :url
    patch_set = [{
      :op => :add,
      :path => "/relations/-",
      :value => {
        :rel => :AttachedFile,
        :url => attachment.url,
        :attributes => {
          :resourceSize => size.to_s
        }
      }
    }]
    update workitem.id, patch_set
  end

  def update workitem_id, patch_set
    return if patch_set.length == 0
    body = patch_set.to_json
    url = mstfs_url "wit/workitems/#{workitem_id}"
    response = http_patch url, body, PATCH_HEADER
    process_response response
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
        value: relation
      }
    end
  end

  #def attachment_resource
  #  @attachment_resource ||= TFSAttachmentResource.new(@service)
  #end
end
