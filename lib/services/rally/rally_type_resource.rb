class RallyTypeResource < RallyResource
  def get_type_definitions
    returnHash = Hashie::Mash.new
    url = rally_url "/typedefinition?start=1&pagesize=200"
    response = http_get url
    process_response(response) do |document|
      logger.info "Got rally type definition response: " + document.inspect
      document.QueryResult.Results.each do |result|
        returnHash[result["_refObjectName"]] = result["_refObjectUUID"]
      end
    end

    returnHash
  end
end
