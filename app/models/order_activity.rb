class OrderActivity < ApplicationRecord
  scope :buy, -> { where('content like ?', '%手中购买了这件物品') }
  scope :sell, -> { where('content like ?', '%的价格出售了这件物品') }
end
