require 'base64'

class RallyAttachmentContentResource < RallyResource
  def create file_url
    open(file_url) do |file|
      url = rally_secure_url "/attachmentcontent/create"
      body = { :AttachmentContent => { :Content => Base64.strict_encode64(file.read()) }}.to_json
      response = http_put url, body
      process_response response do |document|
        return document.CreateResult.Object
      end
    end
  end

  def delete_by_url url
    token = get_security_token
    url = url + "?key=#{token}"
    process_response http_delete(url), 200, 201
  end
end
