class P2PMProjectResource < P2PMResource

  attr_accessor :security_token

  def all

    sec_token = get_security_token
    http.headers["Authorization"] = "Bearer " + sec_token
    response = http_get @service.data.data_url + "/api/1.0/workflow/pmtable"
    process_response response do |body|
      
      tables = Hashie::Mash.new
      parsed = JSON.parse(body)
      
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
  
end