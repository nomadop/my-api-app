class MarketAsset < ApplicationRecord
  include ActAsGooItem
  self.inheritance_column = nil
  self.primary_key = :classid

  has_one :inventory_description, foreign_key: :classid
  has_one :order_histogram, primary_key: :item_nameid, foreign_key: :item_nameid

  def load_order_histogram
    Market.load_order_histogram(item_nameid)
  end
end
