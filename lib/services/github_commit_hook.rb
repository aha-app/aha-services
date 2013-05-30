class AhaServices::GithubCommitHook < AhaService
  callback_url

  def receive_webhook
    puts "Got webhook"
    puts payload.inspect
    
    # Create a comment for each commit where the message contains a feature
    # or requirement ID.
    payload.commits.each do |commit|
      commit.message
      
      commit.message.scan(/([A-Z]+-[0-9]+(?:-[0-9]+)?)/) do |m|
        m.each do |ref|
          comment_on_record(ref, commit)
        end
      end
    end
  end
  
protected

  def comment_on_record(ref_num, commit)
    record_type = ref_num =~ /-R-/ ? "requirements" : "features"
    api.create_comment(record_type, ref_num, "commit")
  end
  
end