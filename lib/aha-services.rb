require 'active_support'
ActiveSupport::JSON

require 'net/http'
require 'net/https'
require 'pp'

require 'faraday'
require 'faraday_middleware'
require 'ipaddr'
require 'socket'
require 'hashie'
require 'aha-api'

require 'aha-services/version'
require 'aha-services/networking'
require 'aha-services/schema'
require 'aha-services/errors'
require 'aha-services/api'
require 'aha-services/documentation'
require 'aha-services/helpers'
require 'aha-services/service'
require 'aha-services/logger'

require 'services/github/github_resource'
require 'services/github/github_repo_resource'
require 'services/github/github_milestone_resource'

require 'services/redmine/redmine_resource'
require 'services/redmine/redmine_project_resource'

Dir["#{File.dirname(__FILE__)}/services/**/*.rb"].each {|file| require file }