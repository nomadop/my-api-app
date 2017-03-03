class InventoryDescription < ApplicationRecord
  include ActAsGooItem
  self.inheritance_column = nil

  has_many :assets,
           ->(description) { where(instanceid: description.instanceid) },
           class_name: 'InventoryAsset', primary_key: :classid, foreign_key: :classid
  belongs_to :market_asset, foreign_key: :classid

  scope :marketable, -> { where(marketable: 1) }
  scope :unmarketable, -> { where(marketable: 0) }

  def load_market_asset
    return false if unmarketable?

    ApplicationJob.perform_unique(LoadMarketAssetJob, market_hash_name: market_hash_name)
  end

  def marketable?
    marketable == 1
  end

  def unmarketable?
    marketable == 0
  end
end
