class BuyOrder < ApplicationRecord
  include ActAsListable

  PPG_SQL = '1.0 * price / market_assets.goo_value'

  after_create :refresh_status_later

  belongs_to :market_asset, primary_key: :market_hash_name, foreign_key: :market_hash_name
  has_one :order_histogram, through: :market_asset
  has_many :other_orders, class_name: 'BuyOrder', primary_key: :market_hash_name, foreign_key: :market_hash_name
  has_one :active_order, -> { where(active: 1) },
          class_name: 'BuyOrder', primary_key: :market_hash_name, foreign_key: :market_hash_name

  scope :success, -> { where(success: 1) }
  scope :active, -> { where(active: 1) }
  scope :purchased, -> { where(purchased: 1) }
  scope :purchased_active, -> { active.where(market_hash_name: BuyOrder.purchased.distinct.pluck(:market_hash_name)) }
  scope :without_active, -> { left_outer_joins(:active_order).where(active_orders_buy_orders: {market_hash_name: nil}) }
  scope :without_market_asset, -> { left_outer_joins(:market_asset).where(market_assets: {market_hash_name: nil}) }
  scope :with_in, ->(duration, table_name = :buy_orders) { where("#{table_name}.created_at > ?", duration.ago) }
  scope :with_in_ppg, ->(ppg = MarketAsset::DEFAULT_PPG_VALUE) { joins(:market_asset).where("#{PPG_SQL} < #{ppg}") }

  default_scope { where(success: 1) }

  scope :part_purchased, -> { where('quantity_remaining < quantity AND active = 1') }
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

  delegate :load_order_histogram, :goo_value, :item_nameid, to: :market_asset
  delegate :lowest_sell_order, :highest_buy_order, to: :order_histogram

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

    def auto_rebuy_later
      find_each(&:auto_rebuy_later)
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
        quantity = row.search('.market_listing_buyorder_qty .market_listing_price').inner_text.strip
        {
            buy_orderid: buy_orderid,
            market_hash_name: market_hash_name,
            success: 1,
            active: 1,
            purchased: 0,
            quantity: quantity,
            quantity_remaining: quantity,
        }
      end
      active.update_all(active: 0, purchased: 1, quantity_remaining: 0)
      import(orders, on_duplicate_key_update: {
          conflict_target: [:buy_orderid],
          columns: [:success, :active, :purchased, :quantity_remaining],
      })
    end

    def refresh_active
      active.includes(:market_asset).refresh_order_histogram_later
    end

    # def rebuy_purchased
    #   Authentication.refresh
    #   3.times do
    #     break if BuyOrder.refresh
    #   end
    #   BuyOrder.part_purchased.rebuy_later
    #   market_hash_names = BuyOrder.purchased.without_active.distinct.pluck(:market_hash_name)
    #   MarketAsset.where(market_hash_name: market_hash_names).quick_order_later
    #   market_hash_names.size
    # end

    def rebuy_purchased
      Authentication.refresh
      Market.scan_my_histories
      sleep 30.seconds
      MarketAsset.with_my_buy_histories(10.minute).quick_order_later
    end

    def rebuy_all
      Authentication.refresh
      3.times do
        break if BuyOrder.refresh
      end
      MarketAsset.orderable(MarketAsset::DEFAULT_PPG_VALUE).buyable(2).without_active_buy_order.quick_order_later
      rebuy_cancelable
    end

    def rebuy_cancelable
      cancelable = BuyOrder
          .cancelable
          .includes(:market_asset, :order_histogram)
          .reject { |buy_order| buy_order.highest_buy_order >= buy_order.goo_value * MarketAsset::DEFAULT_PPG_VALUE }
      cancelable.each(&:rebuy_later)
    end

    def remaining_price
      sum('price * quantity_remaining')
    end

    def purchased_count
      sum('quantity - quantity_remaining')
    end

    def purchased_price
      sum('price * (quantity - quantity_remaining)')
    end

    def group_by_ppg(precision = 2)
      joins(:market_asset).group("round(#{PPG_SQL}, #{precision})").order("round(#{PPG_SQL}, #{precision})")
    end

    def purchased_goo_value
      sum('market_assets.goo_value * (quantity - quantity_remaining)')
    end
  end

  def refresh_status
    status = Market.get_buy_order_status(buy_orderid)
    update(status)
    rebuy_later if (quantity || 1) > (quantity_remaining || 0)
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
        update(active: 0, purchased: 1)
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
    cancel && market_asset.quick_order_later(true)
  end

  def rebuy_later
    ApplicationJob.perform_unique(CancelBuyorderJob, id, true)
  end

  def auto_rebuy
    return if market_asset.nil?

    Market.load_order_histogram(item_nameid)
    market_asset.refresh_goo_value
    return rebuy if price.nil?
    return rebuy if 1.0 * price / goo_value > MarketAsset::DEFAULT_PPG_VALUE
    return rebuy if quantity > BuyOrder.purchased.with_in(3.days).where(market_hash_name: market_hash_name).count
    return if price > highest_buy_order
    return if 1.0 * (highest_buy_order + 1) / goo_value > MarketAsset::DEFAULT_PPG_VALUE

    rebuy
  end

  def auto_rebuy_later
    AutoRebuyJob.perform_later(id)
  end
end
