class OrderHistogram < ApplicationRecord
  belongs_to :market_asset, primary_key: :item_nameid, foreign_key: :item_nameid

  def proportion
    1.0 * highest_buy_order / lowest_sell_order
  end

  def highest_buy_order_exclude_vat
    Utility.exclude_val(highest_buy_order)
  end

  def lowest_sell_order_exclude_vat
    Utility.exclude_val(lowest_sell_order)
  end

  def refresh
    Market.load_order_histogram(item_nameid)
  end

  def refresh_later
    ApplicationJob.perform_unique(LoadOrderHistogramJob, item_nameid)
  end
end
