require 'open-uri'
require 'base64'

class BugzillaAttachmentResource < BugzillaResource
  def create bug_id, aha_attachment
    file = URI.parse(aha_attachment.download_url).open

    data = file.read()
    # TODO: The documentation states that the data should be base64 encoded if not plain ascii
    # but it seems that it ALWAYS expects it to be encoded
    data = Base64.strict_encode64(data) #unless data.ascii_only?
    attachment = {
      :ids => [ bug_id ],
      :file_name => aha_attachment.file_name,
      :summary => aha_attachment.file_name,
      :content_type => aha_attachment.content_type,
      :data => data
    }
    body = attachment.to_json
    url = bugzilla_url "bug/#{bug_id}/attachment"
    response = http_post url, body
    process_response response
  end

  def update id, aha_attachment
    file = URI.parse(aha_attachment.download_url).open
    data = file.read()
    data = Base64.strict_encode64(data) unless data.ascii_only?
    attachment = { :data => data }
    body = attachment.to_json
    url = bugzilla_url "bug/attachment/#{id}"
    process_response http_put(url, body)
  end
end
