class InventoryDescription < ApplicationRecord
  include ActAsGooItem
  self.inheritance_column = nil

  has_many :assets, class_name: 'InventoryAsset',
           primary_key: [:classid, :instanceid], foreign_key: [:classid, :instanceid]
  belongs_to :market_asset, foreign_key: :classid, optional: true

  scope :marketable, -> { where(marketable: 1) }
  scope :unmarketable, -> { where(marketable: 0) }

  def load_market_asset
    return false if unmarketable?

    ApplicationJob.perform_unique(LoadMarketAssetJob, nil, market_hash_name)
  end

  def marketable_date
    matches = owner_descriptions&.map do |description|
      match = description['value'].match(/\[date\](?<timestamp>\d+)\[\/date\]后可交易/)
      match && Time.at(match[:timestamp].to_i).to_date.to_s
    end
    matches && matches.compact.first
  end

  def marketable?
    marketable == 1
  end

  def unmarketable?
    marketable == 0
  end
end
