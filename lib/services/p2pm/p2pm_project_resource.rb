class P2PMProjectResource < P2PMResource
  require 'net/http'
  require 'uri'
  require 'json'
  
  attr_accessor :security_token

  def all

    uri = URI.parse("http://52.39.212.230:8080/workflow/oauth2/token")
    header = {'Content-Type': 'application/json',}
    user = {user: {
              grant_type: 'password',
              scope: '*',
              client_id: 'ORFAVREOUWRAUGGRQJGTNKDRHKBSETWT',
              client_secret: '434157704590a695188bf57026369405',
              userame: 'admin',
              password: 'admin'
              }
            }

puts uri
puts user.to_json

# Create the HTTP objects
http = Net::HTTP.new(uri.host, uri.port)
request = Net::HTTP::Post.new(uri.request_uri, header)
request.body = user.to_json

# Send the request
response = http.request(request)
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
