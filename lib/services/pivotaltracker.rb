class AhaServices::Pivotaltracker < AhaService

  @@api_url = 'https://www.pivotaltracker.com/services/v5'

  def receive_create_feature
    add_story
  end

  def add_story()
    prepare_request
    response = http_post '%s/projects/%s/stories' % [@@api_url, data.project_id], '{"name":"Exhaust ports are ray shielded"}'
=begin
    process_response(response, 200) do |updated_issue|
      logger.info("Updated issue ")
    end
=end
  end

  def prepare_request
    http.headers['Content-Type'] = 'application/json'
    http.headers['X-TrackerToken'] = data.api_token
  end

end