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
    url = @service.data.data_url + "/api/1.0/workflow/pmtable/" + table + "/data"
    #url = mstfs_project_url project, "wit/workitems/$" + ERB::Util.url_encode(type)
    #logger.debug "Sending request to #{url}\nBody: #{body}\n"
    bearer = 'Bearer ' + security_token
    #response = http_patch url, body.to_json, my_header
    response = RestClient.post url, body.to_json, { content_type: :json,:Authorization => bearer } { |response, request, result, &block|
      case response.code
        when 201
          p "It worked !"
          response
        when 400
          puts response.code
          msg = parse(response.body)
          puts msg
        when 423
          raise SomeCustomExceptionIfYouWant
        else
          puts response.code
#          RestClient::
#          response.return!(&block)
      end
    }
    process_RestClient_response response
  end

  def create_case aha_feature, security_token
    #logger.debug "\n#{aha_feature}\n"
    #logger.debug "Creating case for #{aha_feature.reference_num}\n"
    projid = get_projectid security_token
    #logger.debug "PM Project ID: #{projid}"
    userid = get_userid security_token, aha_feature.release.project.name
    #logger.debug "PM User ID: #{userid}"
    taskid = get_taskid projid, security_token
    #logger.debug "PM Task ID: #{taskid}"
    description = aha_feature.description.to_hash;
    #requirement = aha_feature.requirements.to_hash;
    #logger.debug "requirements hash #{requirement}"
    send_requirement = ""
    aha_feature.requirements.each do |requirement|
      myrequirement = requirement.to_hash
      #logger.debug "myrequirement: #{myrequirement}"
      #logger.debug "name: #{myrequirement['name']}"
      #logger.debug "body: #{myrequirement['description']['body']}"
      send_requirement += "#{myrequirement['name']}<br><br>#{myrequirement['description']['body']}<br>"
    end
    #logger.debug "send_requirement: #{send_requirement}"
    epic_id = aha_feature.initiative.id
    epic_name = aha_feature.initiative.name
    #logger.debug "epic: #{epic_id}: #{epic_name}"
    theme_name = ""
    theme_id = ""
    aha_feature.goals.each do |goal|
      theme = goal.to_hash
      theme_name = theme['name']
      theme_id = theme['id']
      #logger.debug "theme: #{theme_id}: #{theme_name}"
    end
    theme_tfs_id = nil
    epic_tfs_id = nil
    theme_tfs_id = get_theme_info "goals", theme_id, projid
    epic_tfs_id = get_theme_info "initiatives", epic_id, projid
    body = {
      "pro_uid" => projid,
	    "usr_uid" => userid,
	    "tas_uid" => taskid,
      "app_title" => aha_feature.reference_num,
	    "variables" => [
		    {
			    "ahaId" => aha_feature.reference_num,
          "ahaGUID" => aha_feature.id,
			    "customer" => get_custom_field_value(aha_feature,"customer"),
			    "owner" => get_custom_field_value(aha_feature,"salesforce_case_owner"),
			    "product" => aha_feature.release.project.name,
			    "reproSteps" => get_custom_field_value(aha_feature,"bug_repro_steps"),
			    "salesforceId" => get_custom_field_value(aha_feature,"salesforce_id"),
          "bugVersion" => get_custom_field_value(aha_feature,"bug_version_found_in"),
          "areaPath" => get_custom_field_value(aha_feature,"area_path"),
          "iterationPath" => get_custom_field_value(aha_feature,"iteration_path"),
			    "title" => aha_feature.name,
          "requirements" => send_requirement,
          "description" => description['body'],
          "valuestream" => get_custom_field_value(aha_feature,"value_stream"),
          "severity" => get_custom_field_value(aha_feature, "bug_severity"),
          "customer_priority" => get_custom_field_value(aha_feature, "customer_priority"),
          "epic" => epic_tfs_id,
          "theme" => theme_tfs_id,
			    "type" => aha_feature.workflow_kind.name
		    }
      ]
    }
    #body = (to_field_patch_array(fields) + to_relation_patch_array(links) ).to_json
    http.headers["Authorization"] = "Bearer " + security_token
    url = @service.data.data_url + "/api/1.0/workflow/cases/impersonate"
    #url = mstfs_project_url project, "wit/workitems/$" + ERB::Util.url_encode(type)
    #logger.debug "Sending request to #{url}\nBody: #{body}\n"
    bearer = 'Bearer ' + security_token
    #response = http_patch url, body.to_json, my_header
    response = RestClient.post url, body.to_json, { content_type: :json,:Authorization => bearer } { |response, request, result, &block|
      case response.code
        when 200
          p "It worked !"
          #logger.debug "response\n #{response} \n"
          response
        when 400
          p "Error"
          msg = parse(response.body)
          puts msg
          response
        when 423
          raise SomeCustomExceptionIfYouWant
#        else
#          RestClient::
#          response.return!(&block)
      end
    }
    process_RestClient_response response
  end

  def update_case app_uid, security_token
    #logger.debug "Updating case #{app_uid}\n"
    http.headers["Authorization"] = "Bearer " + security_token
    url = @service.data.data_url + "/api/1.0/workflow/cases/2540916815963f560e2bad6090350234/variable"
    #url = mstfs_project_url project, "wit/workitems/$" + ERB::Util.url_encode(type)
    bearer = 'Bearer ' + security_token
    body = { "newCaseId" => app_uid }
    #response = http_patch url, body.to_json, my_header
    response = RestClient.put url, body, { content_type: :json,:Authorization => bearer } { |response, request, result, &block|
      case response.code
        when 200
          p "It worked !"
          response
        when 400
          p "Error!"
          response
        when 423
          raise SomeCustomExceptionIfYouWant
        else
          RestClient::
          response.return!(&block)
      end
    }
    #logger.debug "response: #{response}"
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

  def get_theme_info(type, theme_id, project_id)
    #loggerlogger.debug "In get_theme_info\n"
    http.headers["Authorization"] = "Bearer cef088bcdaecbfb6ea8563394a17f1e2ccece4f335fdac75809a6e8ac54c07cb"
    response = http_get "https://secure.aha.io/api/v1/products/" + project_id + "/" + type + "/" + theme_id
    process_response response do |body|
      parsed = JSON.parse(body)
      #logger.debug "\nparsed: #{parsed}\n"
      if (type == "goals")
        #logger.debug "\ncustom_fields: #{parsed['goal']['custom_fields']}\n"
        tfs_id = parsed['goal']['custom_fields'].find {|field| field['key'] == "tfs_id"}
      else
        #logger.debug "\ncustom_fields: #{parsed['initiative']['custom_fields']}\n"
        tfs_id = parsed['initiative']['custom_fields'].find {|field| field['key'] == "tfs_id"}
      end
      #logger.debug "\ntfs_id: #{tfs_id['value']}\n"
      tfs_id['value']
    end
  end

  def get_projectid sec_token
    #logger.debug "In get_projectid\n"
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

  def get_userid sec_token, product
    #logger.debug "In get_userid\n"
    http.headers["Authorization"] = "Bearer " + sec_token
    table_id = ""
    # Get the table ID from process maker 
    response = http_get @service.data.data_url + "/api/1.0/workflow/pmtable"
    process_response response do |body|
      parsed = JSON.parse(body)
      parsed.each do |table|
        if table['pmt_tab_name'] == "PMT_TFS_DEV_MANAGER"
          table_id = table['pmt_uid']
        end
      end
    end
    if table_id != ""
      pm_userid = ""
      response = http_get @service.data.data_url + "/api/1.0/workflow/pmtable/" + table_id + '/data?q={"where": {"product": "' + product + '"}}'
      process_response response do |body|
        parsed = JSON.parse(body)
        pm_userid = parsed["rows"][0]["username"]
      end
      
      if pm_userid != ""

        # Get the record in the table for the product
        response = http_get @service.data.data_url + "/api/1.0/workflow/users"
        process_response response do |body|
          
          users = Hashie::Mash.new
          parsed = JSON.parse(body)
          user_id = nil
          parsed.each do |user|
            if user['usr_username'] == pm_userid
              user_id = user['usr_uid']
            end
          end
          user_id
        end
      end
    end
  end
  
  def get_taskid project_id, sec_token
    #logger.debug "In get_taskid\n"
    http.headers["Authorization"] = "Bearer " + sec_token
    response = http_get @service.data.data_url + "/api/1.0/workflow/project/" + project_id
    process_response response do |body|
      
      tasks = Hashie::Mash.new
      parsed = JSON.parse(body)
      #logger.debug "\nbody: #{body}\n"
      x = parsed["diagrams"][0]
      #logger.debug "\ndiagrams #{x}\n"
      y = x["activities"][0]
      #logger.debug "\nactivities #{y}\n"
      z = y["act_name"]
      #logger.debug "\nact_name: #{z}\n"
      z1 = y["act_uid"]
      #logger.debug "\nact_uid:  #{z1}\n"
      task_id = z1
      task_id
    end
  end

  #def attachment_resource
  #  @attachment_resource ||= TFSAttachmentResource.new(@service)
  #end
end
