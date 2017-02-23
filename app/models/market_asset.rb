class MarketAsset < ApplicationRecord
  include ActAsGooItem
  self.inheritance_column = nil

  class << self
    def load_from_listing(market_hash_name)
      response = RestClient.get("http://steamcommunity.com/market/listings/753/#{market_hash_name}")
      html = response.body
      assets = Utility.match_json_var('g_rgAssets', html)
      asset = assets&.values&.[](0)&.values&.[](0)&.values&.[](0)
      asset_model = MarketAsset.find_or_create_by(id: asset['id'])
      asset_model.update(asset)
    end
  end
end
