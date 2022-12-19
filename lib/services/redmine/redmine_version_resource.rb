class RedmineVersionResource < RedmineResource

  def create
    prepare_request
    params = parse_payload @payload.release
    logger.debug("PARAMS: #{params.to_json}")
    response = http_post redmine_versions_path, params.to_json
    process_response response, 201 do |body|
      create_integrations 'releases', @payload.release.reference_num,
        {id: body.version.id, name: body.version.name, url: "#{@service.data.redmine_url}/versions/#{body.version.id}"}
    end
  end

  def update
    prepare_request
    params = parse_payload @payload.release
    version_id = get_integration_field @payload.release.integration_fields, 'id'
    response = http_put("#{@service.data.redmine_url}/versions/#{version_id}.json", params.to_json)
    process_response response, 200, 204 do
      logger.info("Updated version #{version_id}")
    end
  end

private

  def redmine_versions_path *concat
    str = "#{@service.data.redmine_url}/projects/#{@service.data.project}/versions"
    str = str + '/' + concat.join('/') unless concat.empty?
    str + '.json'
  end

  def parse_payload payload_fragment
    return Hashie::Mash.new( version: {
      name: payload_fragment.name,
      due_date: payload_fragment.release_date,
      description: "Created from Aha! #{payload_fragment.url}",
    })
  end

end
