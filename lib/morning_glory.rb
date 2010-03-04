# Prefix files with a revision to bust the cloudfront non-expiring cache. For instance, /REV_1234/myfile.png
CLOUDFRONT_REVISION_PREFIX = 'REV_'

begin
  CLOUDFRONT_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/morning_glory.yml")[Rails.env]
rescue
  raise "Error loading MorningGlory configuration files. Please check config/morning_glory.yml is configured correctly."
end

begin
  S3_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/s3.yml")[Rails.env]
rescue
  raise "Error loading MorningGlory configuration files. Please check config/s3.yml is configured correctly."
end

if defined? CLOUDFRONT_CONFIG
  if CLOUDFRONT_CONFIG['enabled'] == true
    ENV['RAILS_ASSET_ID'] = CLOUDFRONT_REVISION_PREFIX + CLOUDFRONT_CONFIG['revision'].to_s
  end
end
