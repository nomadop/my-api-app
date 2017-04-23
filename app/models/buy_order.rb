class BuyOrder < ApplicationRecord
  include ActAsListable

  after_create :refresh_status_later

  belongs_to :market_asset, primary_key: :market_hash_name, foreign_key: :market_hash_name
  has_one :order_histogram, through: :market_asset

  scope :success, -> { where(success: 1) }
  scope :active, -> { where(active: 1) }
  scope :cancelable, ->(ppg = 0.5) { joins(:market_asset).where('active = 1 AND 1.0 * price / market_assets.goo_value > ?', ppg) }
  default_scope { where(success: 1) }

  scope :cancelable, -> do
    joins(:order_histogram).where(
        <<-SQL
        (price < order_histograms.highest_buy_order OR (
          price = order_histograms.highest_buy_order AND 
          CAST(order_histograms.buy_order_graph->0->>1 AS int) > 1
        )) AND (
          order_histograms.id = (
            SELECT id FROM order_histograms oh 
            INNER JOIN market_assets ma 
            ON oh.item_nameid = ma.item_nameid 
            WHERE ma.market_hash_name = market_assets.market_hash_name 
            ORDER BY oh.created_at DESC LIMIT 1
          )
        ) AND ( buy_orders.active = 1 )
    SQL
    )
  end

  delegate :load_order_histogram, to: :market_asset
  delegate :lowest_sell_order, to: :order_histogram

  class << self
    def refresh_order_histogram_later
      find_each(&:refresh_order_histogram_later)
    end

    def refresh_status
      find_each(&:refresh_status)
    end

    def refresh_status_later
      find_each(&:refresh_status_later)
    end

    def cancel
      find_each(&:cancel)
    end

    def refresh_active_orders
      doc = Nokogiri::HTML(Market.request_market)
      listing_rows = doc.search('.market_listing_row.market_recent_listing_row')
      order_rows = listing_rows.select { |row| /mybuyorder_\d+/ =~ row.attr(:id) }
      return if order_rows.blank?

      order_ids = order_rows.map { |row| row.attr(:id).match(/\d+/)[0] }
      transaction do
        active.update(active: 0)
        unscoped.where(buy_orderid: order_ids).update(success: 1, active: 1)
      end
    end
  end

  def refresh_status
    status = Market.get_buy_order_status(buy_orderid)
    update(status)
  end

  def refresh_status_later
    ApplicationJob.perform_unique(RefreshOrderStatusJob, id, wait: 3.seconds)
  end

  def refresh_order_histogram_later
    market_asset.load_order_histogram
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
