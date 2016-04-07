class RallyUserResource < RallyResource
  def user_id_for_email(email)
    url = rally_url_without_workspace("/user?" + {query: "(EmailAddress = #{email})"}.to_query)
    process_response http_get(url) do |document|
      user = document.QueryResult.Results.first
      return user["_ref"] if user
    end
  end
end
