class RedmineVersionResource < RedmineResource

  def create
    prepare_request
    params = parse_payload @payload.release
    response = http_post redmine_versions_path, params
    process_response response, 201 do |body|
      create_integrations @payload.release.reference_num,
        id: body.version.id,
        name: body.version.name,
        url: redmine_versions_path(body.version.id)
    end
  end

  def update
    prepare_request
    params = parse_payload @payload.release
    version_id = get_integration_field @payload.release.integration_fields, 'id'
    response = http_put redmine_versions_path(version_id), params
    process_response response, 200 do
      create_integrations @payload.release.reference_num,
        id: version_id,
        name: params.version.name,
        url: redmine_versions_path(version_id)
      logger.info("Updated version #{version_id}")
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
