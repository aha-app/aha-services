lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
require 'aha-services/version'

Gem::Specification.new do |s|
  s.name        = "aha-services"
  s.version     = AhaServices::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Chris Waters"]
  s.email       = ["chris@aha.io"]
  s.homepage    = "http://aha.io/"
  s.summary     = "Web hooks for aha.io"
  s.description = ""

  s.required_rubygems_version = ">= 1.3.6"

  s.add_development_dependency "rspec"
  s.add_development_dependency "webmock"
  s.add_dependency "hashie", "~> 2.1.1"
  s.add_dependency "faraday", "~> 0.8.9"
  s.add_dependency "faraday_middleware", "~> 0.9.0"
  s.add_dependency "simple_oauth"
  s.add_dependency "activesupport"
  s.add_dependency "htmlentities"

  # For Jira integration.
  s.add_dependency "html2confluence"

  # For Trello integration.
  s.add_dependency "reverse_markdown"

  # For Redmine integration.
  s.add_dependency "ClothRed"

  s.add_dependency "aha-api"

  s.files        = Dir.glob("{lib}/**/*") + %w(LICENSE README.md)
  s.require_path = 'lib'
end
