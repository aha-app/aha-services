class RallyUserResource < RallyResource
  def user_id_for_email(email)
    url = rally_url_without_workspace("/user?" + {query: "((EmailAddress = #{email}) OR (UserName = #{email}))"}.to_query)
    process_response http_get(url) do |document|
      user = document.QueryResult.Results.first
      return user["_ref"] if user
    end
  end

  def email_from_ref(reference)
    process_response(http_get(reference)) do |document|
      return document.User.EmailAddress rescue nil
    end
  end
end
