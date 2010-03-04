require 'action_view/helpers/asset_tag_helper'

module ActionView::Helpers::AssetTagHelper

  def rewrite_asset_path(source)
    asset_id = rails_asset_id(source)
    if asset_id.blank?
      source
    else
      # TODO: Look at config
      if CLOUDFRONT_CONFIG['enabled'] == true  
        # /REV_123/stylesheets/main.css
        if request.ssl?
          if !AssetHostingWithMinimumSsl::asset_ssl_host.nil?
            # This in on an SSL CDN host, cache bust as normal
            File.join('/', ENV['RAILS_ASSET_ID'], source)
          else
            # This is on an SSL host so not on the CDN, cache bust via query string
            source + "?#{asset_id}"
          end
        else
          # Non SSL CDN, cache bust as normal
          File.join('/', ENV['RAILS_ASSET_ID'], source)
        end
      else
        source + "?#{asset_id}"
      end
   end
  end

end

