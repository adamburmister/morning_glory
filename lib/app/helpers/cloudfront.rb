require 'action_view/helpers/asset_tag_helper'

module ActionView::Helpers::AssetTagHelper

  def rewrite_asset_path(source)
    asset_id = rails_asset_id(source)
    if asset_id.blank?
      source
    else
      if ENV['RAILS_ENV'] == 'development' || request.ssl?
        source + "?#{asset_id}"
      else
        # /REV_123/stylesheets/main.css
        File.join('/', ENV['RAILS_ASSET_ID'], source)
      end
    end
  end

end
