class P2PMProjectResource < P2PMResource

  attr_accessor :security_token

  def all

    # body = {
    #   'grant_type' => "password",
    #   'scope' => "*",
    #   'client_id' => @service.data.client_id,
    #   'client_secret' => @service.data.client_secret,
    #   'username' => @service.data.user_name,
    #   'password' => @service.data.user_password
    # }
    
    # response = RestClient.post @service.data.server_url, body.to_json, {content_type: :json, accept: :json} { |response, request, result, &block|
    #   case response.code
    #     when 200
    #       p "It worked !"
    #       response
    #     when 423
    #       raise SomeCustomExceptionIfYouWant
    #     else
    #       response.return!(&block)
    #   end
    # }
    # puts response
    # parsed = JSON.parse(response)
    # security_token = parsed['access_token']
    # puts security_token
    # @service.data.security_token = security_token
    # #response = http_post @service.data.server_url, body.to_json
    # #process_response response do |document|
    # #  self.security_token = document.OperationResult.SecurityToken
    # #end
    sec_token = get_security_token
    http.headers["Authorization"] = "Bearer " + sec_token
    response = http_get "http://52.39.212.230:8080/api/1.0/workflow/pmtable"
    process_response response do |body|
      
      tables = Hashie::Mash.new
      p "In processing body"
      parsed = JSON.parse(body)
      puts parsed
      
      parsed.each do |table|
        #if table['pmt_tab_name'] == 'TFS_DATA'
        #  tab_uid = table['pmt_uid']
        #end
        table_id = table['pmt_uid']
        table_name = table['pmt_tab_name']
        #tables[table["pmt_uid"]] = Hashie::Mash.new({:id => table["pmt_uid"], :name => table.["pmt_tab_name"]})
        tables[table_id] = Hashie::Mash.new({:id => table_id, :name => table_name })
      end
      tables
    end
  end
protected
  def get_security_token
    body = {
      'grant_type' => "password",
      'scope' => "*",
      'client_id' => @service.data.client_id,
      'client_secret' => @service.data.client_secret,
      'username' => @service.data.user_name,
      'password' => @service.data.user_password
    }
    
    response = RestClient.post @service.data.server_url, body.to_json, {content_type: :json, accept: :json} { |response, request, result, &block|
      case response.code
        when 200
          p "It worked !"
          response
        when 423
          raise SomeCustomExceptionIfYouWant
        else
          response.return!(&block)
      end
    }
    puts response
    parsed = JSON.parse(response)
    security_token = parsed['access_token']
    security_token
  end
end