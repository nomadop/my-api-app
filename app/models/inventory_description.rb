class InventoryDescription < ApplicationRecord
  include ActAsGooItem
  self.inheritance_column = nil
  
end
