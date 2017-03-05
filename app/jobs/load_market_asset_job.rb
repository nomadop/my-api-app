class LoadMarketAssetJob < ApplicationJob
  queue_as :market_asset

  def perform(option)
    Market.load_asset_by_url(option[:url]) if option[:url]
    Market.load_asset_by_hash_name(option[:market_hash_name]) if option[:market_hash_name]
  end
end
