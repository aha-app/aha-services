class AhaServices::Redmine < AhaService
  title 'Redmine'
  service_name 'redmine_issues'

  string :redmine_url
  string :api_key
  select :project, collection: -> (meta_data, data) { meta_data.projects.collect { |p| [p.name, p.id] } },
    description: "Redmine project that this Aha! product will integrate with."

#========
# EVENTS
#======

  def receive_installed
    @meta_data.projects ||= []

    prepare_request
    response = http_get("#{data.redmine_url}/projects.json")
    process_response(response, 200) do |body|
      body['projects'].each do |project|
        @meta_data.projects << {
          :id => project['id'],
          :name => project['name'],
        }
      end
    end
  end

private

  def prepare_request
    http.headers['Content-Type'] = 'application/json'
    http.headers['X-Redmine-API-Key'] = data.api_key
  end

  def process_response(response, *success_codes, &block)
    if success_codes.include?(response.status)
      yield parse(response.body)
    elsif [404, 403, 401, 400].include?(response.status)
      error = parse(response.body)
      error_string = "#{error['code']} - #{error['error']} #{error['general_problem']} #{error['possible_fix']}"
      raise AhaService::RemoteError, "Error code: #{error_string}"
    else
      raise AhaService::RemoteError, "Unhandled error: STATUS=#{response.status} BODY=#{response.body}"
    end
  end

  def parse(body)
    if body.nil? or body.length < 2
      {}
    else
      JSON.parse(body)
    end
  end

end