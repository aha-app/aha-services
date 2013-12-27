require "#{File.dirname(__FILE__)}/jira"

class AhaServices::JiraConnect < AhaServices::Jira
  title "JIRA via Connect"
  
  install_button
  select :project, collection: ->(meta_data, data) { meta_data.projects.collect{|p| [p.name, p['key']] } }
  select :feature_issue_type, 
    collection: ->(meta_data, data) { 
      meta_data.projects.detect {|p| p['key'] == data.project}.issue_types.find_all{|i| !i['subtype']}.collect{|p| [p.name, p.id] } 
    }, description: "Issue type that will be used for Jira issues."
  select :requirement_issue_type, 
    collection: ->(meta_data, data) { 
      meta_data.projects.detect {|p| p['key'] == data.project}.issue_types.find_all{|i| !i['subtype']}.collect{|p| [p.name, p.id] } 
    }, description: "JIRA issue type that will be used when sending requirements. If you are using JIRA Agile then we recommend 'Story'."
  internal :feature_status_mapping
  internal :resolution_mapping
  
  def auth_header
    # No auth here - we are doing it with middleware.
  end
  
  def faraday_builder(builder)
    builder.request :add_jira_user, data.user_id
    builder.request :oauth, consumer_key: data.consumer_key, 
      consumer_secret: data.consumer_secret, signature_method: "RSA-SHA1"
  end
  
end

class AddJiraUser < Faraday::Middleware
  
  def initialize(app, user_id)
    @app = app
    @user_id = user_id
  end

  def call(env)
    uri = env[:url] 
    uri.query = [uri.query, "user_id=#{@user_id}"].compact.join('&') 

    @app.call(env)
  end
end

Faraday.register_middleware :request, :add_jira_user => lambda { AddJiraUser }
