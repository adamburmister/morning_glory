require 'config/initializers/staging_cdn_revision'
require 'config/initializers/production_cdn_revision'

if defined? CDN_REVISION
  if CDN_REVISION[Rails.env]
    ENV['RAILS_ASSET_ID'] = CDN_REVISION[Rails.env]
  end
end
