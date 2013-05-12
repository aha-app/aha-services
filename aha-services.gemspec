lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
 
sha = `git rev-parse HEAD 2>/dev/null || echo unknown`
sha.chomp!

Gem::Specification.new do |s|
  s.name        = "aha-services"
  s.version     = "1.0.0.#{sha[0,7]}"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Chris Waters"]
  s.email       = ["chris@aha.io"]
  s.homepage    = "http://aha.io/"
  s.summary     = "Web hooks for aha.io"
  s.description = ""
 
  s.required_rubygems_version = ">= 1.3.6"
 
  s.add_development_dependency "rspec"
  s.add_dependency "faraday"
  s.add_dependency "activesupport"
 
  s.files        = Dir.glob("{lib}/**/*") + %w(LICENSE README.md)
  s.require_path = 'lib'
end