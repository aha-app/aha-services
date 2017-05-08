class P2PMProjectResource < P2PMResource
  require './processmaker'  

  attr_accessor :security_token

  def all

# ProcessMaker instance
url = 'http://52.39.212.230:8080/workflow/en/classic/services/wsdl2'

# Login first
Processmaker.login(wsdl: url, user_id: 'admin', password: 'admin')

users = Processmaker.user_list
users.each do |u|
	u[:name]
  puts u[:name]
end

    body = [{
      :grant_type => "password",
      :scope => "*",
      :client_id => "ORFAVREOUWRAUGGRQJGTNKDRHKBSETWT",
      :client_secret => "434157704590a695188bf57026369405",
      :username => "admin",
      :password => "admin"
    }]

    puts body.to_json
    puts @service.data.server_url
    response = http_post @service.data.server_url do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['Cache-Control'] = 'no-cache'
      req.headers['Postman-Token'] = '2e534444-f11f-12af-9053-205ceddd98a0'
      req.body = body.to_json
    end
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
