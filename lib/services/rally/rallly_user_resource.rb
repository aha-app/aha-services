class RallyUserResource < RallyResource
  def user_id_for_email(email)
    url = rally_url_without_workspace("/user?" + {query: "(EmailAddress = #{email})"}.to_query)
    process_response http_get(url) do |document|
      return document.QueryResult.Results.first.try(&:ObjectID)
    end
  end
end
