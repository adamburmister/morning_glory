# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "morning_glory/version"

Gem::Specification.new do |s|
  s.name        = 'morning_glory'
  s.version     = MorningGlory::VERSION
  s.date        = '2011-07-21'
  s.summary     = "Morning Glory is comprised of a rake task and helper methods that manages the deployment of static assets into an Amazon CloudFront CDN’s S3 Bucket, improving the performance of static assets on your Rails web applications."
  s.description = File.read(File.join(File.dirname(__FILE__), 'README.textile'))
  s.platform    = Gem::Platform::RUBY
  s.required_ruby_version = '>=1.9'
  s.authors     = ["Adam Burmister", "Todd Sedano"]
  s.email       = 'professor@gmail.com'
  s.homepage    = 'https://github.com/professor/morning_glory'
  s.license = 'MIT'                    
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]  
  s.add_development_dependency 'aws-s3'
  s.add_development_dependency 'rails'
  s.add_runtime_dependency 'aws-s3'
  s.add_runtime_dependency 'rails'
#  s.has_rdoc	  = false  
# s.test_files = Dir["test/test*.rb"]
# s.executables = [ 'anagram' ]

end