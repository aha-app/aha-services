class AhaServices::GithubCommitHook < AhaService
  title "Github Commit Hook"
  
  callback_url

  # Create a comment for each commit where the message contains a feature
  # or requirement ID.
  def receive_webhook
    commit_payload = Hashie::Mash.new(JSON.parse(payload.payload))
    
    commit_payload.commits.each do |commit|  
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
    
    message = <<EOF
<p>#{commit.committer.name} (#{commit.committer.email}) committed to <a href="#{commit_payload.repository.url}">#{commit_payload.repository.name}</a>:</p>
<blockquote><pre>#{commit.message}</pre></blockquote>
<p>Commit: <a href="#{commit.url}">#{commit.url}</a></p>
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