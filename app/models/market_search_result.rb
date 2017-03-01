class MarketSearchResult < ApplicationRecord
  has_one :market_asset

  def load_market_asset
    return unless market_asset.nil?

    MarketAsset.transaction do
      self.market_asset = Market.load_asset_by_url(listing_url)
      save
    end
  end

  def load_market_asset_later
    return unless market_asset.nil?

    ApplicationJob.perform_unique(LoadMarketAssetJob, market_search_result_id: id)
  end
end
