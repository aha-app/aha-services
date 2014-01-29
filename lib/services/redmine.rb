class AhaServices::Redmine < AhaService
  title 'Redmine'
  service_name 'redmine_issues'

  string :redmine_url
  string :api_key
  select :project,
    collection: -> (meta_data, data) do
      meta_data.projects.collect { |p| [p.name, p.id] }
    end,
    description: "Redmine project that this Aha! product will integrate with."
  select :version,
    collection: -> (meta_data, data) do
      meta_data.projects.find {|p| p.id.to_s == data.project_id.to_s }.versions.collect{|p| [p.name, p.id] }
    end,
    description: "Redmine project versions."

  PARAMLISTS = {
    version: [:name, :description, :sharing, :status]
  }

#========
# EVENTS
#======

  def receive_installed
    install_projects
  end

  def receive_create_project
    project_name = payload.project_name
    project_identifier = project_name.downcase.squish.gsub( /\s/, '-' )

    create_project project_name, project_identifier
  end

  def receive_create_version
    project_id = payload.project_id
    version_name = payload.version_name

    create_version project_id, version_name
  end

  def receive_update_project
    id = payload['id']
    new_name = payload['project_name']

    update_project id, new_name
  end

  def receive_update_version
    project_id = payload['project_id']
    version_id = payload['version_id']
    params = payload['version']

    update_version project_id, version_id, params
  end

  def receive_delete_project
    id = payload['id']

    delete_project id
  end

private

#===============
# EVENT METHODS
#=============

  def install_projects
    @meta_data.projects = []

    prepare_request
    response = http_get("#{data.redmine_url}/projects.json")
    process_response(response, 200) do |body|
      body['projects'].each do |project|
        @meta_data.projects << {
          :id => project['id'],
          :name => project['name'],
        }
        install_versions project['id']
      end
    end
  end

  def install_versions project_id
    project = find_project project_id
    project[:versions] = []

    prepare_request
    response = http_get("#{data.redmine_url}/projects/#{project_id}/versions.json")
    process_response response, 200 do |body|
      next if body.empty?
      body.deep_symbolize_keys!
      body[:versions].each do |version|
        project[:versions] << {
          id: version['id'],
          name: version['name'],
          description: version['description'],
          status: version['status'],
          sharing: version['sharing']
        }
      end
    end
  end

  def create_project name, identifier
    @meta_data.projects ||= []

    prepare_request
    params = { project:{ name: name, identifier: identifier }}
    response = http_post("#{data.redmine_url}/projects.json", params.to_json)
    process_response(response, 200) do |body|
      @meta_data.projects << {
        :id => body['project']['id'],
        :name => body['project']['name']
      }
    end
  end

  def create_version project_id, version_name
    @meta_data.projects ||= []
    install_projects if @meta_data.projects.empty?
    project = find_project project_id
    project[:versions] ||= []

    prepare_request
    params = { version: { name: version_name }}
    response = http_post("#{data.redmine_url}/projects/#{project_id}/versions.json", params.to_json)
    process_response(response, 201) do |body|
      body.deep_symbolize_keys!
      project[:versions] << {
        id: body[:version][:id],
        name: body[:version][:name],
        description: body[:version][:description],
        status: body[:version][:status],
        sharing: body[:version][:sharing]
      }
    end
  end

  def update_project id, new_name
    @meta_data.projects ||= []
    project = find_project id

    prepare_request
    params = { project:{ name: new_name }}
    response = http_put("#{data.redmine_url}/projects/#{id}.json", params.to_json)
    process_response(response, 200) do
      if project
        project[:name] = new_name
      else
        @meta_data.projects << {
          :id => id,
          :name => new_name
        }
      end
    end
  end

  def update_version project_id, version_id, **params
    project = find_project project_id
    version = find_version project, version_id
    params = sanitize_params params, :version

    prepare_request
    response = http_put("#{data.redmine_url}/projects/#{project_id}/versions/#{version_id}.json", params.to_json)
    process_response(response, 200) do
      if project && version
        params.deep_symbolize_keys!
        params.each do |key, val|
          version[key] = val
        end
      else
        install_projects
      end
    end
  end

  def delete_project id
    @meta_data.projects ||= []
    project = find_project id

    prepare_request
    response = http_delete("#{data.redmine_url}/projects/#{id}.json")
    process_response(response, 200) do
      if project
        @meta_data.projects.delete project
      end
    end
  end

#==================
# REQUEST HANDLING
#================

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

#=========
# SUPPORT
#=======

  def find_project project_id
    @meta_data.projects.find {|p| p[:id] == project_id }
  end

  def find_version project_id, version_id
    project = project_id.is_a?(Hash) ? project_id : find_project(project_id)
    project[:versions].find {|v| v[:id] == version_id }
  end

  def sanitize_params params, paramlist_name
    paramlist = PARAMLISTS[paramlist_name]
    params.select {|key, value| paramlist.include? key.to_sym}
  end

end