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

  def create_case aha_feature, security_token
    logger.debug "Creating case for #{aha_feature.reference_num}\n"
    projid = get_projectid security_token
    logger.debug "PM Project ID: #{projid}"
    userid = get_userid security_token
    logger.debug "PM User ID: #{userid}"
    taskid = get_taskid projid, security_token
    logger.debug "PM Task ID: #{taskid}"
    body = {
      "pro_uid" => projid,
	    "usr_uid" => userid,
	    "tas_uid" => taskid,
	    "variables" => [
		    {
			    "ahaId" => aha_feature.reference_num,
			    "customer" => get_custom_field_value(aha_feature,"customer"),
			    "owner" => get_custom_field_value(aha_feature,"salesforce_case_owner"),
			    "product" => aha_feature.release.project.name,
			    "reproSteps" => get_custom_field_value(aha_feature,"bug_repro_steps"),
			    "salesforceId" => get_custom_field_value(aha_feature,"salesforce_id"),
			    "title" => aha_feature.name,
			    "type" => aha_feature.workflow_kind.name
		    }
      ]
    }
    #body = (to_field_patch_array(fields) + to_relation_patch_array(links) ).to_json
    http.headers["Authorization"] = "Bearer " + security_token
    #url = "http://52.39.212.230:8080/api/1.0/workflow/pmtable/" + table + "/data"
    url = @service.data.data_url + "/api/1.0/workflow/cases/impersonate"
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
    body = patch_set
    url = @service.data.data_url + "/api/1.0/workflow/pmtable/" + table + "/data"
    bearer = 'Bearer ' + sec_token
    response = http_put url, body, { 'Content-Type'=> 'application/json', 'Authorization' => bearer }
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

  def get_custom_field_value(resource, key)
    field = resource.custom_fields.find {|field| field['key'] == key}
    if field
      field.value
    else
      nil
    end
  end

  def get_projectid sec_token
    logger.debug "In get_projectid\n"
    http.headers["Authorization"] = "Bearer " + sec_token
    response = http_get @service.data.data_url + "/api/1.0/workflow/project"
    process_response response do |body|
      
      projects = Hashie::Mash.new
      parsed = JSON.parse(body)
      project_id = nil
      parsed.each do |project|
        if project['prj_name'] == "Aha! to TFS"
          project_id = project['prj_uid']
        end
      end
      project_id
    end
  end

  def get_userid sec_token
    logger.debug "In get_userid\n"
    http.headers["Authorization"] = "Bearer " + sec_token
    response = http_get @service.data.data_url + "/api/1.0/workflow/users"
    process_response response do |body|
      
      users = Hashie::Mash.new
      parsed = JSON.parse(body)
      user_id = nil
      parsed.each do |user|
        if user['usr_username'] == "pwaller"
          user_id = user['usr_uid']
        end
      end
      user_id
    end
  end
  
  def get_taskid project_id, sec_token
    logger.debug "In get_taskid\n"
    http.headers["Authorization"] = "Bearer " + sec_token
    response = http_get @service.data.data_url + "/api/1.0/workflow/project/" + project_id
    process_response response do |body|
      
      tasks = Hashie::Mash.new
      parsed = JSON.parse(body)
      logger.debug "\nbody: #{body}\n"
      task_id = nil
      parsed.each do |task|
        logger.debug "\ntask: #{task}\n"
        x = task["diagrams"][0]
        logger.debug "\ndiagrams #{x}\n"
        #if task["diagrams"][0]["activities"][0]["act_name"] == "Approve Bug"
        #  task_id = task["diagrams"][0]["activities"][0]["act_uid"]
        #end
      end
      task_id
    end
  end

  #def attachment_resource
  #  @attachment_resource ||= TFSAttachmentResource.new(@service)
  #end
end
