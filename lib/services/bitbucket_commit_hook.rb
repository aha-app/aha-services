require "mail"
class AhaServices::BitbucketCommitHook < AhaService
  title "Bitbucket Commit Hook"
  caption "Create Aha! comments from Bitbucket commits"

  callback_url

  # Create a comment for each commit where the message contains a feature
  # or requirement ID.
  def receive_webhook
    raw_payload = payload.try(:payload) || payload
    commit_payload = if raw_payload.is_a?(String)
                       Hashie::Mash.new(JSON.parse(raw_payload))
                     elsif raw_payload.is_a?(Hash)
                       Hashie::Mash.new(raw_payload)
                     else
                       raise "Unknown type: #{raw_payload.class.inspect} for payload.payload"
                     end
    commits = Array(commit_payload&.push&.changes&.flat_map(&:commits)).compact
    commits.each do |commit|
      commit.message.scan(/([A-Z]+-[0-9]+(?:-[0-9]+)?)/) do |m|
        m.each do |ref|
          comment_on_record(ref, commit)
        end
      end
    end
  end

protected

  def comment_on_record(ref_num, commit)
    record_type = ref_num =~ /-[0-9]+-/ ? "requirements" : "features"

    email = Mail::Address.new(commit.author.raw)
    message = <<-EOF
      <p>#{email.display_name || email.address} committed:</p>
      <pre>#{commit.message}</pre>
      <p>Commit: <a href="#{commit.links.html.href}">#{commit["hash"]}</a></p>
    EOF

    begin
      api.create_comment(record_type, ref_num, email.address, message)
    rescue AhaApi::NotFound
      # Ignore errors for unknown references - it might not have really
      # been a reference.
      logger.warn("No record found for reference: #{ref_num}")
    end
  end

end
