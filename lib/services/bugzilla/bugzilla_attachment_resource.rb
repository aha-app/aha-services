require 'open-uri'
require 'base64'

class BugzillaAttachmentResource < BugzillaResource
  def create bug_id, aha_attachment
    open(aha_attachment.download_url) do |file|
      data = file.read()
      data = Base64.strict_encode64(data) unless data.ascii_only?
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
  end
end
