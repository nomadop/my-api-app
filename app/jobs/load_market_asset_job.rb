class LoadMarketAssetJob < ApplicationJob
  queue_as :market_asset

  def perform(url, market_hash_name = nil)
    Utility.timeout(12) do
      Market.load_asset_by_url(url) if url
      Market.load_asset_by_hash_name(market_hash_name) if market_hash_name
    end
  end
end
