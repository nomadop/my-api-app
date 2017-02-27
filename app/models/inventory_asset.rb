class InventoryAsset < ApplicationRecord
  has_one :description,
          ->(asset) { where(instanceid: asset.instanceid) },
          class_name: 'InventoryDescription', primary_key: :classid, foreign_key: :classid

  has_one :market_asset, through: :description
end
