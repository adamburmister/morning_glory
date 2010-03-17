require 'action_view/helpers/asset_tag_helper'

module ActionView::Helpers::AssetTagHelper

  def rewrite_asset_path(source)
    asset_id = rails_asset_id(source)
    if asset_id.blank?
      source
    else
      # If the request isn't SSL, or if the request is SSL and the SSL host is set
      if !request.ssl? || (request.ssl? && !AssetHostingWithMinimumSsl::asset_ssl_host.empty?)
        File.join('/', ENV['RAILS_ASSET_ID'], source)
      else
        source + "?#{asset_id}"
      end
    end
  end

end