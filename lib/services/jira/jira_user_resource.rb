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

  private

  def lookup_user(query)
    return nil if query.blank?
    response = http_get "#{api_url}/user/picker?query=#{CGI.escape(query)}"
    return nil if response.status == 404
    process_response(response, 200) do |response_data|

      # Multiple partial matches can be returned from the search, so we sort
      # the results to prioritize complete matches. The return values do not
      # include relevant fields like emailAddress, so to avoid needing to
      # fetch each user again just to read the actual properties, we look at
      # the html match text that shows all the details to see if it's
      # highlighted in there as a whole word (i.e. surrounded by spaces).
      #
      highlighed_word = %r{ <strong>#{query}</strong> }i
      return Array(response_data.users).max_by { |u|
        [u['name'].to_s, u['key'].to_s]
        .map { |v| v.casecmp(query).zero? }
          .push(u['html'].to_s =~ highlighed_word)
          .map { |v| v ? 1 : 0 }
          .reduce(:+)
      }

    end
  end
end
