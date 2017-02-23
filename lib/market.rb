class Market
  class << self
    def load_asset(market_hash_name)
      response = RestClient.get("http://steamcommunity.com/market/listings/753/#{market_hash_name}")
      html = response.body
      assets = Utility.match_json_var('g_rgAssets', html)
      asset = assets&.values&.[](0)&.values&.[](0)&.values&.[](0)
      asset_model = MarketAsset.find_or_create_by(classid: asset['classid'])
      asset_model.update(asset.except('id'))
    end
  end
end