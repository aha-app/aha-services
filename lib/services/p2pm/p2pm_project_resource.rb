class P2PMProjectResource < P2PMResource

  attr_accessor :security_token

  def all

    body = {
      'grant_type' => "password",
      'scope' => "*",
      'client_id' => @service.data.client_id,
      'client_secret' => @service.data.client_secret,
      'username' => @service.data.user_name,
      'password' => @service.data.user_password
    }
    header = {
      'Content-Type' => 'application/json'
    }
    http.headers['Content-Type'] = 'application/json'
    response = http_post @service.data.server_url, body.to_json
    process_response response do |document|
      self.security_token = document.OperationResult.SecurityToken
    end

    http.headers["Authorization"] = "Bearer " + security_token
    response = http_get pm_url("pmtable")
    process_response response do |body|
      tables = Hashie::Mash.new
      body.value.each do |table|
        tables[table.pmt_uid] = Hashie::Mash.new({:id => table.pmt_uid, :name => table.pmt_tab_name})
      end
      tables
    end
  end
end
