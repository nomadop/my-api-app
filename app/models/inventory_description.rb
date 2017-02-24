class InventoryDescription < ApplicationRecord
  include ActAsGooItem
  self.inheritance_column = nil

  has_many :assets,
           ->(description) { where(instanceid: description.instanceid) },
           class_name: 'InventoryAsset', primary_key: :classid, foreign_key: :classid
  belongs_to :market_asset, foreign_key: :classid

  def load_market_asset
    return false if marketable == 0
    return false unless market_asset.nil?

    queue = Sidekiq::Queue.new
    in_queue = queue.any? { |job| job.display_class == 'LoadMarketAssetJob' && job.display_args == [market_hash_name] }
    return false if in_queue

    LoadMarketAssetJob.perform_later(market_hash_name)
  end
end
