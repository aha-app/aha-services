$TEST_ENV = true
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

# This explicit bundler load is required to make specs run properly in my
# textmate.
require 'rubygems'
require 'bundler'
Bundler.require(:default, :development)

require 'rspec'
require 'webmock/rspec'
require 'aha-services'
require 'services/github/github_resource'
require 'services/github/github_repo_resource'
require 'services/github/github_milestone_resource'

Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
end

