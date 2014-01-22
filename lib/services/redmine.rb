class AhaServices::Redmine < AhaService
  title 'Redmine'
  service_name 'redmine_issues'

  string :project_name
  string :api_key
end