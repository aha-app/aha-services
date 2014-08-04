require 'fogbugz'
require 'sanitize'
require 'open-uri'

class AhaServices::Fogbugz < AhaService
  title 'Fogbugz'

  string :fogbugz_url
  string :api_key # g3ai353gges79trub8pge4fmrvlvgr

  install_button
  select :projects, collection: -> (meta_data, data) do
    meta_data.projects.sort_by(&:sProject).collect { |project| [project.sProject, project.ixProject] }
  end

#========
# EVENTS
#========

  def receive_installed
    meta_data.projects = fogbugz_api.command(:listProjects)['projects']['project']
  end

  def receive_create_feature
    create_or_update_case
  end

  def receive_update_feature
    create_or_update_case
  end

#==============
# Api Methods
#==============

  def create_or_update_case
    feature = payload.feature

    parameters = {
      sTitle: feature.name, 
      sEvent: Sanitize.fragment(feature.description.body).strip,
      sTags: feature.tags,
      ixProject: data.projects
    }

    command = :new
    if fogbugz_case = fetch_case(feature)
      command = :edit
      parameters['ixBug'] = fogbugz_case['ixBug']
    end

    attachments = feature.description.attachments.map do |attachment|
      {:filename => attachment.file_name, :file => open(attachment.download_url)}
    end

    fogbugz_case = fogbugz_api.command(command, parameters, attachments)
    integrate_resource_with_case(feature, fogbugz_case["case"])
  end

  def fetch_case(feature)
    case_number = get_integration_field(feature.integration_fields, 'number')
    found_case = fogbugz_api.command(:search, q: "case:#{ case_number }")
    found_case.try(:[], 'cases').try(:[], 'case')
  end


  private

    def fogbugz_api
      @fogbugz_api ||= Fogbugz::Interface.new(token: data.api_key, uri: data.fogbugz_url) # remember to use https!
    end

    def integrate_resource_with_case(feature, fogbugz_case)
      api.create_integration_fields(reference_num_to_resource_type(feature.reference_num), feature.reference_num, self.class.service_name, 
        {number: fogbugz_case['ixBug'], url: "#{data.fogbugz_url}/f/cases/#{fogbugz_case["ixBug"]}"})
    end

end