require 'rubygems'
require 'bundler/setup'

require 'active_support'
ActiveSupport::JSON

require 'net/http'
require 'net/https'
require 'net/http/persistent'
require 'rubyntlm'
require 'pp'

require 'faraday'
require 'clothred'
require 'faraday_middleware'
require 'ipaddr'
require 'socket'
require 'hashie'
require 'aha-api'
require 'rest-client'

require 'aha-services/version'
require 'aha-services/networking'
require 'aha-services/schema'
require 'aha-services/errors'
require 'aha-services/api'
require 'aha-services/documentation'
require 'aha-services/helpers'
require 'aha-services/service'
require 'aha-services/logger'

require 'services/generic_resource'

require 'services/github/github_resource'
require 'services/gitlab/gitlab_resource'
require 'services/bitbucket/bitbucket_resource'
require 'services/jira/jira_resource'
require 'services/jira/jira_mapped_fields'
require 'services/pivotal_tracker/pivotal_tracker_resource'
require 'services/pivotal_tracker/pivotal_tracker_project_dependent_resource'
require 'services/trello/trello_resource'
require 'services/fogbugz/fogbugz_resource'
require 'services/tfs/tfs_common'
require 'services/tfs/tfs_resource'
require 'services/rally/webhook'
require 'services/rally/rally_resource'
require 'services/bugzilla/bugzilla_resource'

require 'services/p2pm/p2pm_common'
require 'services/p2pm/p2pm_resource'

require 'services/redmine/redmine_resource'
require 'services/redmine/redmine_upload_resource'
require 'services/redmine/redmine_project_resource'
require 'services/redmine/redmine_version_resource'
require 'services/redmine/redmine_issue_resource'

Dir["#{File.dirname(__FILE__)}/services/**/*.rb"].each {|file| require file }
