require 'erb'

class RallyPortfolioItemResource < RallyResource

  def get_all_types
    query = ERB::Util.url_encode "((TypePath contains \"PortfolioItem\") and (Ordinal >= 0))"
    url = rally_url "/typedefinition?query=#{query}&fetch=true"
    response = http_get url
    process_response response do |document|
      return document.QueryResult.Results.sort_by{|t| t.Ordinal}.map{|t| t._refObjectName}
    end
  end
end
