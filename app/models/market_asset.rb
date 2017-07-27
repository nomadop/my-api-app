class MarketAsset < ApplicationRecord
  include ActAsGooItem
  include ActAsListable
  include ActAsBoosterPack
  self.inheritance_column = nil
  self.primary_key = :classid

  DEFAULT_PPG_VALUE = 0.4

  has_one :steam_app, primary_key: :market_fee_app, foreign_key: :steam_appid
  has_many :my_listings, primary_key: :market_hash_name, foreign_key: :market_hash_name
  has_many :my_histories, primary_key: :market_hash_name, foreign_key: :market_hash_name
  has_many :my_buy_histories, -> { where('who_acted_with like ?', '卖家%') },
           class_name: 'MyHistory', primary_key: :market_hash_name, foreign_key: :market_hash_name
  has_many :my_sell_histories, -> { where('who_acted_with like ?', '买家%') },
           class_name: 'MyHistory', primary_key: :market_hash_name, foreign_key: :market_hash_name
  has_many :inventory_description, foreign_key: :classid
  has_many :marketable_inventory_description, -> { where(marketable: 1) },
           class_name: 'InventoryDescription', foreign_key: :classid
  has_many :marketable_inventory_asset, through: :marketable_inventory_description, source: :assets
  has_many :order_histograms, primary_key: :item_nameid, foreign_key: :item_nameid
  has_one :order_histogram, -> { where(latest: true) },
          primary_key: :item_nameid, foreign_key: :item_nameid
  has_many :buy_orders, primary_key: :market_hash_name, foreign_key: :market_hash_name
  has_many :active_buy_orders, -> { where(active: 1) },
           class_name: 'BuyOrder', primary_key: :market_hash_name, foreign_key: :market_hash_name
  has_many :sell_histories, primary_key: :classid, foreign_key: :classid
  has_one :booster_creator, primary_key: :market_fee_app, foreign_key: :appid
  has_many :inventory_assets, -> { where(account_id: 1) },
           primary_key: :classid, foreign_key: :classid

  scope :sack_of_gems, -> { where(market_hash_name: '753-Sack of Gems') }
  scope :by_game_name, ->(name) { where('type SIMILAR TO ?', "#{name} (#{Market::ALLOWED_ASSET_TYPE.join('|')})") }
  scope :trading_card, -> { where('type LIKE \'%Trading Card\'') }
  scope :booster_pack, -> { where(type: 'Booster Pack') }
  scope :with_my_listing, -> { joins(:my_listings).distinct }
  scope :without_my_listing, -> { left_outer_joins(:my_listings).where(my_listings: {classid: nil}) }
  scope :buyable, ->(ppg = DEFAULT_PPG_VALUE) { joins(:order_histograms).where('1.0 * order_histograms.lowest_sell_order / goo_value <= ?', ppg).distinct }
  scope :orderable, ->(ppg = DEFAULT_PPG_VALUE) { joins(:order_histograms).where('1.0 * order_histograms.highest_buy_order / goo_value < ?', ppg).distinct }
  scope :with_active_buy_order, -> { joins(:active_buy_orders).distinct }
  scope :without_active_buy_order, -> { left_outer_joins(:active_buy_orders).where(buy_orders: {market_hash_name: nil}) }
  scope :without_order_histogram, -> { left_outer_joins(:order_histograms).where(order_histograms: {item_nameid: nil}) }
  scope :without_sell_history, -> { left_outer_joins(:sell_histories).where(sell_histories: {classid: nil}) }
  scope :with_marketable_inventory_asset, -> { joins(:marketable_inventory_asset).distinct }
  scope :with_sell_histories, -> { joins(:sell_histories).distinct }
  scope :with_my_buy_histories, -> { joins(:my_buy_histories).distinct }
  scope :with_my_sell_histories, -> { joins(:my_sell_histories).distinct }

  JOIN_LATEST_ORDER_HISTOGRAM_SQL = <<-SQL
      JOIN order_histograms
      ON order_histograms.item_nameid = market_assets.item_nameid
      AND order_histograms.id = (
        SELECT id FROM order_histograms oh 
        WHERE oh.item_nameid = market_assets.item_nameid 
        ORDER BY oh.created_at DESC 
        LIMIT 1
      )
  SQL
  scope :buy_ppg_order, -> { joins(JOIN_LATEST_ORDER_HISTOGRAM_SQL).where.not(goo_value: nil).order('1.0 * order_histograms.highest_buy_order / goo_value') }
  scope :sell_ppg_order, -> { joins(JOIN_LATEST_ORDER_HISTOGRAM_SQL).where.not(goo_value: nil).order('1.0 * order_histograms.lowest_sell_order / goo_value') }
  scope :with_booster_creator, -> { joins(:booster_creator).distinct }
  scope :joins_latest_order_histogram, -> { joins(JOIN_LATEST_ORDER_HISTOGRAM_SQL) }
  scope :proportion_more_than, ->(proportion) { where('1.0 * (order_histograms.lowest_sell_order - 1) / (order_histograms.highest_buy_order + 1) > ?', proportion) }
  scope :sell_count_more_than, ->(count) { where('CAST(order_histograms.sell_order_graph->(jsonb_array_length(order_histograms.sell_order_graph) - 1)->>1 AS int) > ?', count) }

  after_create :load_order_histogram, :load_goo_value

  delegate :lowest_sell_order, :highest_buy_order, :lowest_sell_order_exclude_vat, :highest_buy_order_exclude_vat,
           :sell_order_count, :buy_order_count, :order_count, to: :order_histogram, allow_nil: true
  delegate :booster_pack_info, :open_price_per_goo, to: :booster_creator, allow_nil: true

  class << self
    def quick_buy(market_hash_name, ppg = DEFAULT_PPG_VALUE)
      market_asset = find_by(market_hash_name: market_hash_name)
      market_asset.quick_buy(ppg)
    end

    def quick_buy_orderable(ppg = DEFAULT_PPG_VALUE)
      orderable(ppg).buyable(1).find_each { |asset| asset.quick_buy_later(ppg) }
    end

    def quick_buy_later(ppg = DEFAULT_PPG_VALUE, **options)
      find_each { |asset| asset.quick_buy_later(ppg, **options) }
    end

    def quick_order_later
      find_each { |asset| asset.quick_order_later }
    end

    def load_order_histogram
      find_each(&:load_order_histogram)
    end

    def quick_buy_by_ppg(limit, ppg = DEFAULT_PPG_VALUE)
      Authentication.refresh
      sell_ppg_order.first(limit).each {|ma| ma.quick_buy_later(ppg)}
    end
  end

  def load_order_histogram
    return false if item_nameid.nil?

    LoadOrderHistogramJob.perform_later(item_nameid)
  end

  def load_goo_value
    return false if owner_actions.nil?

    ApplicationJob.perform_unique(GetGooValueJob, classid, wait: 3.seconds)
  end

  def refresh_goo_value
    update(goo_value: get_goo_value) if Time.now - updated_at > 1.day
  end

  def booster_pack?
    type == 'Booster Pack'
  end

  def goo_value
    return 1000 if market_hash_name == '753-Sack of Gems'
    booster_pack? && booster_creator ? booster_creator.price : super
  end

  def buy_price_per_goo
    return nil if highest_buy_order.nil? || goo_value.nil?

    1.0 * highest_buy_order / goo_value
  end

  def buy_price_per_goo_exclude_vat
    return nil if goo_value.nil?
    return 0 if highest_buy_order_exclude_vat.nil?

    1.0 * highest_buy_order_exclude_vat / goo_value
  end

  def price_per_goo
    return nil if lowest_sell_order.nil? || goo_value.nil?

    1.0 * lowest_sell_order / goo_value
  end

  def price_per_goo_exclude_vat
    return nil if goo_value.nil?
    return buy_price_per_goo_exclude_vat if lowest_sell_order_exclude_vat.nil?

    1.0 * lowest_sell_order_exclude_vat / goo_value
  end

  def create_buy_order(price, quantity)
    result = Market.create_buy_order(market_hash_name, price, quantity)
    case result['success']
      when 1
        BuyOrder.create(result.merge(market_hash_name: market_hash_name, price: price, quantity: quantity))
      when 8
        Authentication.refresh
        create_buy_order(price, quantity)
      when 29
        return
      else
        raise result['message']
    end
  end

  def quick_buy(ppg)
    return if booster_pack?
    Market.load_order_histogram(item_nameid)
    refresh_goo_value
    graphs = order_histogram.sell_order_graphs.select { |g| 1.0 * g.price / goo_value <= ppg }
    return if graphs.blank?

    active_buy_orders.cancel_later if active_buy_orders.exists?
    graphs.each { |g| ApplicationJob.perform_unique(CreateBuyOrderJob, classid, g.price, g.amount) }
  end

  def quick_buy_later(ppg, **options)
    QuickBuyJob.set(options).perform_later(classid, ppg)
  end

  def quick_order
    return if booster_pack?
    return if active_buy_orders.reload.exists?
    Market.load_order_histogram(item_nameid)
    refresh_goo_value
    highest_buy_order_graph = order_histogram.highest_buy_order_graph
    lowest_price = [(goo_value * 0.1).ceil, 3].max
    highest_price = (goo_value * DEFAULT_PPG_VALUE).floor
    highest_buy_order_graph_price = highest_buy_order_graph.nil? ? lowest_price : highest_buy_order_graph.price + 1
    highest_buy_order_graph_price = highest_price if 1.0 * highest_buy_order_graph_price / goo_value > DEFAULT_PPG_VALUE
    return if 1.0 * highest_buy_order_graph_price / goo_value > DEFAULT_PPG_VALUE

    order_price = [lowest_price, highest_buy_order_graph_price].max
    # quantity = BuyOrder.purchased.with_in(3.days).where(market_hash_name: market_hash_name).count
    # quantity = 1 if quantity < 1
    # quantity = 3 if quantity > 3
    quantity = 1
    ApplicationJob.perform_unique(CreateBuyOrderJob, classid, order_price, quantity)
  end

  def quick_order_later(unique = false)
    unique ?
        ApplicationJob.perform_unique(QuickOrderJob, classid) :
        QuickOrderJob.perform_later(classid)
  end

  def buy_info
    as_json(only: [:market_hash_name, :goo_value], methods: [:price_per_goo])
  end

  def load_sell_histories
    SellHistory.transaction do
      SellHistory.where(classid: classid).delete_all
      self.sell_histories = Market.request_sell_history(listing_url)
    end
  end

  def load_sell_histories_later
    ApplicationJob.perform_unique(LoadSellHistoriesJob, classid)
  end

  def sell_balance(price, with_in: 1.week)
    sell_histories.with_in(with_in).sell_rate(price) - order_histogram.sell_rate(price)
  end

  def sell_histories_deviation
    history_average_price = sell_histories.with_in(1.month).average_price
    history_average_price && {
        classid: classid,
        sell_deviation: history_average_price / order_histogram.lowest_sell_order,
        buy_deviation: history_average_price / order_histogram.highest_buy_order,
    }
  end

  def find_sell_balance(with_in: 1.week, balance: 0)
    graphs = order_histogram.sell_order_graphs
    from = graphs.first.price - 1
    to = graphs.last.price
    prices = from.upto(to).to_a
    balance = prices.reverse.bsearch { |price| sell_balance(price, with_in: with_in) > balance }
    balance || prices.first
  end

  def get_order_activity
    Market.request_order_activity(item_nameid)
  end

  def pull_order_activity
    ApplicationJob.perform_unique(PullOrderActivityJob, item_nameid)
  end

  def refersh
    ApplicationJob.perform_unique(LoadMarketAssetJob, listing_url)
  end
end
