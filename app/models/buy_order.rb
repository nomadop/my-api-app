class BuyOrder < ApplicationRecord
  include ActAsListable

  after_create :refresh_status_later

  belongs_to :market_asset, primary_key: :market_hash_name, foreign_key: :market_hash_name
  has_one :order_histogram, through: :market_asset
  has_many :other_orders, class_name: 'BuyOrder', primary_key: :market_hash_name, foreign_key: :market_hash_name
  has_one :active_order, -> { where(active: 1) },
          class_name: 'BuyOrder', primary_key: :market_hash_name, foreign_key: :market_hash_name

  scope :success, -> { where(success: 1) }
  scope :active, -> { where(active: 1) }
  scope :purchased, -> { where(purchased: 1) }
  scope :without_active, -> { left_outer_joins(:active_order).where(active_orders_buy_orders: {market_hash_name: nil}) }

  default_scope { where(success: 1) }

  scope :cancelable, -> do
    joins(:order_histogram).where <<-SQL
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

    def cancel_later
      find_each(&:cancel_later)
    end

    def rebuy_later
      find_each(&:rebuy_later)
    end

    def refresh
      doc = Nokogiri::HTML(Market.request_market)
      listing_rows = doc.search('.market_listing_row.market_recent_listing_row')
      order_rows = listing_rows.select { |row| /mybuyorder_\d+/ =~ row.attr(:id) }
      return if order_rows.blank?

      orders = order_rows.map do |row|
        buy_orderid = row.attr(:id).match(/\d+/)[0]
        market_url = row.search('.market_listing_item_name_link').attr('href').to_s
        market_hash_name = URI.decode(market_url.split('/').last)
        {buy_orderid: buy_orderid, market_hash_name: market_hash_name, success: 1, active: 1, purchased: 0}
      end
      active.update_all(active: 0, purchased: 1)
      import(orders, on_duplicate_key_update: {
          conflict_target: [:buy_orderid],
          columns: [:success, :active, :purchased],
      })
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
    market_asset.load_order_histogram unless market_asset.nil?
  end

  def price_per_goo
    1.0 * price / market_asset.goo_value
  rescue Exception => _
    Float::INFINITY
  end

  def cancel
    return true if active == 0

    result = Market.cancel_buy_order(buy_orderid)
    case result['success']
      when 1
        update(active: 0)
        return true
      when 8
        if result['error'] == 'Token is required but was not set.'
          Authentication.refresh
          raise 'Token is required but was not set.'
        end

        return false
      else
        return false
    end
  end

  def cancel_later
    ApplicationJob.perform_unique(CancelBuyorderJob, id)
  end

  def rebuy
    cancel && market_asset.quick_order_later
  end

  def rebuy_later
    ApplicationJob.perform_unique(CancelBuyorderJob, id, true)
  end
end
