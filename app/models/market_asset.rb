class MarketAsset < ApplicationRecord
  include ActAsGooItem
  self.inheritance_column = nil
  self.primary_key = :classid

  belongs_to :steam_app, primary_key: :steam_appid, foreign_key: :market_fee_app
  has_one :my_listing, foreign_key: :classid
  has_one :inventory_description, foreign_key: :classid
  has_one :order_histogram, primary_key: :item_nameid, foreign_key: :item_nameid
  has_many :buy_orders, primary_key: :market_hash_name, foreign_key: :market_hash_name

  scope :by_game_name, ->(name) { where('type SIMILAR TO ?', "#{name} (#{Market::ALLOWED_ASSET_TYPE.join('|')})") }
  scope :trading_card, -> { where('type LIKE \'%Trading Card\'') }
  scope :booster_pack, -> { where(type: 'Booster Pack') }
  scope :with_my_listing, -> { joins(:my_listing).distinct }
  scope :without_my_listing, -> { left_outer_joins(:my_listing).where(my_listings: {classid: nil}) }
  scope :buyable, -> { joins(:order_histogram).where('1.0 * order_histograms.lowest_sell_order / goo_value < 0.55') }
  scope :orderable, -> { joins(:order_histogram).where('1.0 * order_histograms.highest_buy_order / goo_value < 0.5') }

  after_create :load_order_histogram, :load_goo_value

  def load_order_histogram
    return false if item_nameid.nil?

    ApplicationJob.perform_unique(LoadOrderHistogramJob, item_nameid)
  end

  def load_goo_value
    return false if owner_actions.nil?

    ApplicationJob.perform_unique(GetGooValueJob, classid, wait: 3.seconds)
  end

  def price_per_goo
    return Float::INFINITY if order_histogram&.lowest_sell_order.nil? || goo_value.nil?

    1.0 * order_histogram.lowest_sell_order / goo_value
  end

  def price_per_goo_exclude_vat
    return Float::INFINITY if order_histogram&.lowest_sell_order_exclude_vat.nil? || goo_value.nil?

    1.0 * order_histogram.lowest_sell_order_exclude_vat / goo_value
  end

  def create_buy_order(price, quantity)
    result = Market.create_buy_order(market_hash_name, price, quantity)
    BuyOrder.create(result.merge(market_hash_name: market_hash_name, price: price)) if result['success'] == 1
  end

  def quick_create_buy_order
    order_histogram.refresh
    highest_buy_order_graph = order_histogram.highest_buy_order_graph
    return if 1.0 * highest_buy_order_graph.price / goo_value > 0.5

    create_buy_order(highest_buy_order_graph.price + 1, 1)
  end

  def quick_create_buy_order_later
    ApplicationJob.perform_unique(CreateBuyOrderJob, classid)
  end
end
