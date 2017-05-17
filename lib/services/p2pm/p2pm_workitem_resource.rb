require 'erb'

class P2PMWorkItemResource < P2PMResource

  PATCH_HEADER = { 'Content-Type'=> 'application/json-patch+json' }

  def by_url url
    response = http_get url
    process_response response
  end

  # Get the ProcessMaker TFS_DATA record by the ID.
  def by_id id, table, sec_token
    http.headers["Authorization"] = "Bearer " + sec_token
    url = @service.data.data_url + "/api/1.0/workflow/pmtable/"+ table + '/data?q={"where": {"ID": ""' + id+ '""}}'
    by_url url
  end

  def create table, body, security_token
    #body = (to_field_patch_array(fields) + to_relation_patch_array(links) ).to_json
    http.headers["Authorization"] = "Bearer " + security_token
    #url = "http://52.39.212.230:8080/api/1.0/workflow/pmtable/" + table + "/data"
    url = @service.data.data_url + "/api/1.0/workflow/pmtable/" + table + "/data"
    #url = mstfs_project_url project, "wit/workitems/$" + ERB::Util.url_encode(type)
    logger.debug "Sending request to #{url}\nBody: #{body}\n"
    bearer = 'Bearer ' + security_token
    #response = http_patch url, body.to_json, my_header
    response = RestClient.post url, body.to_json, { content_type: :json,:Authorization => bearer } { |response, request, result, &block|
      case response.code
        when 201
          p "It worked !"
          response
        when 423
          raise SomeCustomExceptionIfYouWant
        else
          RestClient::
          response.return!(&block)
      end
    }
    process_RestClient_response response
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

  def update workitem_id, patch_set, table, sec_token
    return if patch_set.length == 0
    body = patch_set.to_json
    url = @service.data.data_url + "/api/1.0/workflow/pmtable/" + table + "/data"
    bearer = 'Bearer ' + sec_token
    response = RestClient.put url, body, { 'Content-Type'=> 'application/json', 'Authorization' => bearer }
    process_RestClient_response response
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
