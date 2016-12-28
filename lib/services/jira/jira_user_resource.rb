class JiraUserResource < JiraResource
  def picker(email)
    prepare_request
    response = http_get "#{api_url}/user/picker?query=#{CGI.escape email}"
    if response.status == 404
      return nil
    end
    process_response(response, 200) do |response|
      return response.users.first if response.users && response.users.any?
      nil
    end
  end

  def get(key)
    prepare_request
    response = http_get "#{api_url}/user?key=#{key}"
    if response.status == 404
      return nil
    end
    process_response(response, 200) do |response|
      return response
    end
  end

end
