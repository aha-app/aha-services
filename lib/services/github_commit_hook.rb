class AhaServices::GithubCommitHook < AhaService
  callback_url

  def receive_webhook
    puts "Got webhook"
    puts payload.inspect
    
    # Create a comment for each commit where the message contains a feature
    # or requirement ID.
    payload.commits.each do |commit|
      commit.message
      
      ref_list = []
      commit.message.scan(/([A-Z]+-[0-9]+(?:-[0-9]+)?)/) do |m|
        ref_list.concat(m)
      end
      
      puts "Refs: #{ref_list.inspect}"
    end
  end
  
end