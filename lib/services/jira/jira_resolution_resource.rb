class JiraResolutionResource < JiraResource
  def all
    prepare_request
    response = http_get "#{api_url}/resolution"
    resolutions = []
    process_response(response, 200) do |meta|
      meta.each do |resolution|
        resolutions << {id: resolution.id, name: resolution.name}
      end
    end
    resolutions
  end
end
