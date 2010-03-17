require 'rubygems'  
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the morning_glory plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the morning_glory plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'MorningGlory'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

begin  
  require 'jeweler'  
  Jeweler::Tasks.new do |gemspec|  
    gemspec.name = "morning_glory"  
    gemspec.summary = "Handle the deployment and referencing of assets to the Amazon AWS Cloudfront CDN"  
    gemspec.description = "Improve the performance of your Rails site by storing asset files (images, stylesheets, javascripts) on the Amazon AWS Cloudfront CDN. This gem handles the deployment (via a rake task), expiring old assets on the Cloudfront CDN (via timestamped folder names), and referencing the CDN assets within your site using standard Rails helpers." 
    gemspec.email = "adam@whiterabbitconsulting.eu"  
    gemspec.homepage = "http://github.com/adamburmister/MorningGlory/"  
    gemspec.authors = ["Adam Burmister"]  
    gemspec.add_dependency('aws-s3')
    gemspec.requirements << 'An Amazon AWS S3 and Cloudfront account'
    gemspec.requirements << 'Configured S3 Buckets and Cloudfront Distributions setup and configured, ready to have assets deployed to them.'
    gemspec.requirements << 'AssetHostingWithMinimumSsl plugin installed: script/plugin install git://github.com/dhh/asset-hosting-with-minimum-ssl.git'
  end  
  Jeweler::GemcutterTasks.new
rescue LoadError  
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"  
end  
  
#Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each { |ext| load ext }  
