class AhaServices::BitbucketCommitHook < AhaService
  title "Bitbucket Commit Hook"
  caption "Create Aha! comments from Bitbucket commits"

  callback_url

  # Create a comment for each commit where the message contains a feature
  # or requirement ID.
  def receive_webhook
    commit_payload = Hashie::Mash.new(JSON.parse(payload.payload))
    
    (commit_payload.commits || []).each do |commit|  
      commit.message.scan(/([A-Z]+-[0-9]+(?:-[0-9]+)?)/) do |m|
        m.each do |ref|
          comment_on_record(commit_payload, ref, commit)
        end
      end
    end
  end
  
protected

  def comment_on_record(commit_payload, ref_num, commit)
    record_type = ref_num =~ /-[0-9]+-/ ? "requirements" : "features"
    
    message = <<-EOF
      <p>#{commit.raw_author} committed to <a href="#{commit_payload.canon_url}/#{commit_payload.repository.absolute_url}">#{commit_payload.repository.name}</a>:</p>
      <pre>#{commit.message}</pre>
      <p>Commit: <a href="#{commit_payload.canon_url}/#{commit_payload.repository.absolute_url}/commits/#{commit.raw_node}">#{commit.node}</a></p>
    EOF

    begin
      api.create_comment(record_type, ref_num, commit.committer.email, message)
    rescue AhaApi::NotFound
      # Ignore errors for unknown references - it might not have really
      # been a reference.
      logger.warn("No record found for reference: #{ref_num}")
    end
  end
  
end
