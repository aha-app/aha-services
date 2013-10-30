require "#{File.dirname(__FILE__)}/jira"

class AhaServices::JiraConnect < AhaServices::Jira
  install_button
  select :project, collection: ->(meta_data, data) { meta_data.projects.collect{|p| [p.name, p['key']] } }
  select :feature_issue_type, 
    collection: ->(meta_data, data) { 
      meta_data.projects.detect {|p| p['key'] == data.project}.issue_types.find_all{|i| !i['subtype']}.collect{|p| [p.name, p.id] } 
    }, description: "Issue type that will be used for Jira issues."
  internal :feature_status_mapping
  internal :resolution_mapping
  
  def http(options = {})
    h = super(options)
  end
  
  def prepare_request
    http.headers['Content-Type'] = 'application/json'
    # No auth here - we are doing it with middleware.
  end
  
  def faraday_builder(builder)
    puts "ADDING BUILDER<br/>"
    builder.request :oauth, consumer_key: data.consumer_key, 
      consumer_secret: data.consumer_secret, signature_method: "RSA-SHA1"
  end
end