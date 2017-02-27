class OrderHistogram < ApplicationRecord
  belongs_to :market_asset, primary_key: :item_nameid, foreign_key: :item_nameid

  def highest_buy_order_exclude_vat
    Utility.exclude_val(highest_buy_order)
  end

  def lowest_sell_order_exclude_vat
    Utility.exclude_val(lowest_sell_order)
  end

  def refrest
    Market.load_order_histogram(item_nameid)
  end
end
