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
    puts JSON.generate(payload.feature)
    feature_case = create_or_update_case(payload.feature)
  end

  def receive_update_feature
    feature_case = create_or_update_case(payload.feature)
  end

#==============
# Api Methods
#==============

  def create_or_update_case(feature, parent_case = nil)
    old_attachments = []

    parameters = {
      sTitle: feature.name, 
      sEvent: Sanitize.fragment(feature.description.body).strip,
      sTags: feature.tags,
      ixProject: data.projects
    }

    parameters[:ixBugParent] = parent_case if parent_case

    command = :new
    if fogbugz_case = fetch_case(feature)
      command = :edit
      parameters = set_edit_parameters(fogbugz_case, parameters)
      old_attachments = has_attachments(fogbugz_case)
    end

    attachments = feature.description.attachments.map do |attachment| 
      {:filename => attachment.file_name, :file => open(attachment.download_url)} unless old_attachments.include?(attachment.file_name)
    end

    fogbugz_case = fogbugz_api.command(command, parameters, attachments)["case"]
    integrate_resource_with_case(feature, fogbugz_case)

    if feature.requirements
      feature.requirements.each do |requirement|
        create_or_update_case(requirement, fogbugz_case["ixBug"])
      end
    end

    fogbugz_case
  end


  def set_edit_parameters(fogbugz_case, parameters)
    parameters.delete(:sTitle) if fogbugz_case["sTitle"] == parameters[:sTitle]
    parameters.delete(:sEvent) if fogbugz_case["sLatestTextSummary"] == parameters[:sEvent]
    parameters[:ixBug] = fogbugz_case['ixBug']
    parameters
  end

  def has_attachments(fogbugz_case)
    if case_attachments = fogbugz_case['events']['event']['rgAttachments']
      case_attachments = case_attachments['attachment'].is_a?(Hash) ? [case_attachments['attachment']] : case_attachments['attachment']
      case_attachments.collect {|attachment| attachment['sFileName'] }
    else
      []
    end
  end

  def fetch_case(feature)
    case_number = get_integration_field(feature.integration_fields, 'number')
    found_case = fogbugz_api.command(:search, q: "case:#{ case_number }", cols: "sLatestTextSummary,latestEvent,tags,File1,sTitle")
    puts found_case.try(:[], 'cases').try(:[], 'case')
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