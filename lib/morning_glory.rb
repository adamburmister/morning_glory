begin
  CLOUDFRONT_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/cloudfront_config.yml")[Rails.env]
rescue
end

if defined? CLOUDFRONT_CONFIG
  if CLOUDFRONT_CONFIG['enabled'] == true
    ENV['RAILS_ASSET_ID'] = CLOUDFRONT_CONFIG['revision'].to_s
    require 'asset_tag_helper'
  end
end
