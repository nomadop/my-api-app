class MarketSearchResult < ApplicationRecord
  has_one :market_asset

  def load_market_asset
    return unless market_asset.nil?

    MarketAsset.transaction do
      self.market_asset = Market.load_asset_by_url(listing_url)
      save
    end
  end
end
