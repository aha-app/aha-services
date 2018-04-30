require 'open-uri'

class FogbugzResource < GenericResource

  def initialize(service)
    super(service)
    @token = service.data.api_token
    @url = service.data.fogbugz_url
  end

  def projects
    command(:listProjects).projects.project
  end

  def statuses
    command(:listStatuses).statuses.status
  end

  def command(command, params = {}, attachments = [])
    # add attachments
    if !attachments.empty?
      params[:nFileCount] = attachments.size
      attachments.each_with_index do |attachment, index|
        params["File#{index + 1}"] = Faraday::UploadIO.new(
          URI.parse(attachment[:file_url]).open,
          attachment[:content_type] || 'application/octet-stream',
          attachment[:filename]
          )
      end
      http_reset
      http(:encoding => :multipart)
    end

    params = params.merge!({'token' => @token, 'cols' => request_columns})
    
    params = URI.encode_www_form(params) if attachments.empty?

    response = http_post("#{ api_url }#{ command }", params)
    process_response(response, 200).response
  end

  def process_response(response, *success_codes)
    parsed_response = parse_xml(response.body)
    if success_codes.include?(response.status) && parsed_response && parsed_response['response'].try(:[], 'error').nil?
      hashie_from_response(parsed_response)
    elsif success_codes.include?(response.status) # Fogbugz always returns 200 even on errors
      raise RemoteError, "Error message: #{parsed_response['response']['error']}"
    else
      raise RemoteError, "Unhandled error: STATUS=#{response.status} BODY=#{response.body}"
    end
  end

  def hashie_from_response(parsed_response_body)
    if parsed_response_body.is_a? Array
      parsed_response_body.collect { |element| Hashie::Mash.new(element) }
    else
      Hashie::Mash.new(parsed_response_body)
    end
  end

  def api_url
    "#{ File.join(@url, '/api.asp') }?cmd="
  end

  def request_columns
    "sLatestTextSummary,latestEvent,tags,File1,sTitle,sStatus,ixStatus,fOpen"
  end

end
