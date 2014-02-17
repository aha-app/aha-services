require "#{File.dirname(__FILE__)}/jira"

class AhaServices::JiraConnect < AhaServices::Jira
  title "JIRA via Connect"
  
  install_button
  select :project, collection: ->(meta_data, data) { meta_data.projects.collect{|p| [p.name, p['key']] } }
  boolean :send_initiatives, description: "Check to use feature initatives to create Epics in JIRA Agile"
  select :feature_issue_type, 
    collection: ->(meta_data, data) { 
      meta_data.projects.detect {|p| p['key'] == data.project}.issue_types.find_all{|i| !i['subtype']}.collect{|p| [p.name, p.id] } 
    }, description: "JIRA issue type that will be used when sending features. If you are using JIRA Agile then we recommend 'Story'."
  select :requirement_issue_type, 
    collection: ->(meta_data, data) { 
      meta_data.projects.detect {|p| p['key'] == data.project}.issue_types.find_all{|i| !i['subtype']}.collect{|p| [p.name, p.id] } 
    }, description: "JIRA issue type that will be used when sending requirements. If you are using JIRA Agile then we recommend 'Sub-task'."
  internal :feature_status_mapping
  internal :resolution_mapping
  boolean :send_tags, description: "Check to synchronize Aha! tags and JIRA labels. We recommend enabling this for new integrations. Enabling this option once features are synced to JIRA may cause tags in Aha! or labels in JIRA to be removed from a feature if the corresponding label or tag doesn't exist in the other system."

  
end
