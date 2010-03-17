# Prefix files with a revision to bust the cloudfront non-expiring cache. For instance, /REV_1234/myfile.png
CLOUDFRONT_REVISION_PREFIX = 'REV_'

module MorningGlory
  # Nothing
end

begin
  MORNING_GLORY_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/morning_glory.yml") if !defined? MORNING_GLORY_CONFIG
rescue
  raise "Error loading MorningGlory configuration files. Please check config/morning_glory.yml is configured correctly."
end

begin
  S3_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/s3.yml")[Rails.env] if !defined? S3_CONFIG
rescue
  raise "Error loading MorningGlory configuration files. Please check config/s3.yml is configured correctly."
end

if defined? MORNING_GLORY_CONFIG
  if MORNING_GLORY_CONFIG[Rails.env]['enabled'] == true
    ENV['RAILS_ASSET_ID'] = CLOUDFRONT_REVISION_PREFIX + MORNING_GLORY_CONFIG[Rails.env]['revision'].to_s
  end
end
