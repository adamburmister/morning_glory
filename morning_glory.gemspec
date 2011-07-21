Gem::Specification.new do |s|
  s.name        = 'morning_glory'
  s.version     = '0.0.1'
  s.date        = '2011-07-21'
  s.summary     = "Morning Glory is comprised of a rake task and helper methods that manages the deployment of static assets into an Amazon CloudFront CDN’s S3 Bucket, improving the performance of static assets on your Rails web applications."
  s.description = File.read(File.join(File.dirname(__FILE__), 'README.textile'))
  s.platform    = Gem::Platform::RUBY
  s.required_ruby_version = '>=1.9'
  s.authors     = ["Adam Burmister", "Todd Sedano"]
  s.email       = 'professor@gmail.com'
  s.files	      = Dir['**/**']  
  s.homepage    = 'https://github.com/professor/morning_glory'
  s.license = 'MIT'
  s.add_development_dependency 'aws-s3'
  s.add_runtime_dependency 'aws-s3'
#  s.has_rdoc	  = false  
# s.test_files = Dir["test/test*.rb"]
# s.executables = [ 'anagram' ]

end