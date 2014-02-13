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
  
end
