class MyListing < ApplicationRecord
  include ActAsListable

  after_create :load_market_asset_later

  has_one :market_asset, primary_key: :market_hash_name, foreign_key: :market_hash_name
  has_one :order_histogram, through: :market_asset


  def load_market_asset_later
    ApplicationJob.perform_unique(LoadMarketAssetJob, nil, market_hash_name) if market_asset.nil?
  end
end
