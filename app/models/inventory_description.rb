class InventoryDescription < ApplicationRecord
  include ActAsGooItem
  self.inheritance_column = nil

  has_many :assets,
           ->(description){ where(instanceid: description.instanceid) },
           class_name: 'InventoryAsset', primary_key: :classid, foreign_key: :classid
  belongs_to :market_asset, foreign_key: :classid
end
