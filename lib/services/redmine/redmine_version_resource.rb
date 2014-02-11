class RedmineVersionResource < RedmineResource

  def find id
    prepare_request
    response = http_get "#{redmine_versions_path}/#{id}.json"
    process_response response, 200 do |body|
      return body['versions']
    end
  end

  def create payload_fragment
    prepare_request
    params = parse_payload payload_fragment
    response = http_post redmine_versions_path, params
    process_response response, 201 do |body|
      create_integrations payload_fragment.reference_num,
        id: body.version.id,
        name: body.version.name,
        url: redmine_versions_path(body.version.id)
    end
  end

  def update id, payload_fragment
    prepare_request
    response = http_put "#{redmine_versions_path}/#{id}.json"
    process_response response, 200 do |body|
      return body['versions']
    end
  end

private

  def redmine_versions_path *concat
    str = "#{@service.data.redmine_url}/projects/#{@service.data.project_id}/versions"
    str = str + '/' + concat.join('/') unless concat.empty?
    str + '.json'
  end

  def parse_payload payload_fragment
    return Hashie::Mash.new( version: { name: payload_fragment.name })
  end

end
