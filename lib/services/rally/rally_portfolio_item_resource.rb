class RallyPortfolioItemResource < RallyResource
  def get_all_portfolio_items
    path = "/typedefinition?" + {
      start: 1,
      pagesize: 200,
      query: "(TypePath contains PortfolioItem) and (Ordinal >= 0)",
      fetch: "true"
    }.to_query

    process_response(http_get(rally_secure_url(path))) do |response|
      return response.QueryResult.Results.sort_by{ |result| result.Ordinal } # Lowest Ordinal => Lowest unit on the heirarchy.
    end
  end
end

