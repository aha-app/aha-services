$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

# This explicit bundler load is required to make specs run properly in my
# textmate.
require 'rubygems'
require 'bundler'
Bundler.require(:default)

require 'rspec'
require 'webmock/rspec'
require 'aha-services'

Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}

RSpec.configure do |config|
end
