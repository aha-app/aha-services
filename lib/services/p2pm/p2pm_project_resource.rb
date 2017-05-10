class P2PMProjectResource < P2PMResource

  attr_accessor :security_token

  def all

    body = {
      'grant_type' => "password",
      'scope' => "*",
      'client_id' => "ORFAVREOUWRAUGGRQJGTNKDRHKBSETWT",
      'client_secret' => "434157704590a695188bf57026369405",
      'username' => @service.data.user_name,
      'password' => @service.data.password
    }
    header = {
      'Content-Type' => 'application/json'
    }
    response = http_post (@service.data.server_url, body.to_json, header)
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
