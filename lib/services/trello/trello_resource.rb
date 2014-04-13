class TrelloResource < GenericResource

  def process_response(response, *success_codes, &block)
    if success_codes.include?(response.status)
      yield hashie_or_array_of_hashies(response.body) if block_given?
    elsif response.status.between?(400, 499)
      # Trello returns error messages in plain text.
      raise RemoteError, "Error message: #{response.body}"
    else
      raise RemoteError, "Unhandled error: STATUS=#{response.status} BODY=#{response.body}"
    end
  end

protected
  def api_url
    "https://api.trello.com/1"
  end

  def trello_url(path)
    "https://api.trello.com/1/\
     #{path}?key=#{@service.oauth_key}&token=#{@service.oauth_token}"
  end
end
