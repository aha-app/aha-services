require 'active_support'
ActiveSupport::JSON

require 'net/http'
require 'net/https'
require 'pp'
require 'logger'

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

require 'services/github/github_resource'
require 'services/github/github_repo_resource'
require 'services/github/github_milestone_resource'

Dir["#{File.dirname(__FILE__)}/services/**/*.rb"].each {|file| require file }