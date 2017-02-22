class InventoryAsset < ApplicationRecord
  belongs_to :description,
             ->(asset){ where(instanceid: asset.instanceid) },
             class_name: 'InventoryDescription', primary_key: :classid, foreign_key: :classid

end
