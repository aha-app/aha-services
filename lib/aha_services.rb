require 'aha_services/version'
require 'aha_services/service'

Dir["#{File.dirname(__FILE__)}/services/**/*.rb"].each {|file| require file }