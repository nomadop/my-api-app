class BuyOrder < ApplicationRecord
  include ActAsListable

  after_create :refresh_status_later

  belongs_to :market_asset, primary_key: :market_hash_name, foreign_key: :market_hash_name
  has_one :order_histogram, through: :market_asset

  scope :success, -> { where(success: 1) }
  scope :active, -> { where(active: 1) }
  scope :cancelable, ->(ppg = 0.5) { joins(:market_asset).where('active = 1 AND 1.0 * price / market_assets.goo_value > ?', ppg) }
  default_scope { where(success: 1) }

  delegate :load_order_histogram, to: :market_asset
  delegate :lowest_sell_order, to: :order_histogram

  def refresh_status
    status = Market.get_buy_order_status(buy_orderid)
    update(status)
  end

  def refresh_status_later
    ApplicationJob.perform_unique(RefreshOrderStatusJob, id, wait: 1.seconds)
  end

  def price_per_goo
    1.0 * price / market_asset.goo_value
  rescue Exception => _
    Float::INFINITY
  end

  def cancel
    result = Market.cancel_buy_order(buy_orderid)
    update(active: 0) if result['success'] == 1
  end
end
