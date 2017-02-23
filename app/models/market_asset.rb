class MarketAsset < ApplicationRecord
  include ActAsGooItem
  self.inheritance_column = nil
  self.primary_key = :classid

end
