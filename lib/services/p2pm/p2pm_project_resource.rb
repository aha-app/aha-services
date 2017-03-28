class P2PMProjectResource < P2PMResource
 
  attr_accessor :security_token

  def all
    http.headers["Content-Type"] = "application/json"
    http.headers["Cache-Control"] = "no-cache"
    http.headers["Postman-Token"] = "2e534444-f11f-12af-9053-205ceddd98a0"
    body = '{"client_id":"GDDMSRMYAZCXXZYCORZDDYMZUSCDMSBS","client_secret":"8556684445876ac6758cbd2008857012","username":"pwaller","password":"BaseBall24","grant_type":"password"}'
    response = http_post ("#{server_url}",body)
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
