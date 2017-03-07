class JiraUserResource < JiraResource
  
  # Lookup a user by email or by name if email fails. Lookups by email
  # don't work if JIRA is configure not to show email addresses:
  #   https://confluence.atlassian.com/doc/user-email-visibility-138596.html
  def picker(email, name = nil)  
    result = lookup_user(email)
    if result.nil? and name.present?
      result = lookup_user(name)
    end
    result
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

protected
  
  def lookup_user(q)
    prepare_request
    response = http_get "#{api_url}/user/picker?query=#{CGI.escape(q)}"
    if response.status == 404
      return nil
    end
    process_response(response, 200) do |response|
      return response.users.first if response.users && response.users.any?
      nil
    end
  end
  

end
