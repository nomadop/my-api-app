class BoosterCreator < ApplicationRecord
  before_save :set_trading_card_type

  has_one :steam_app, primary_key: :appid, foreign_key: :steam_appid
  has_one :booster_pack, -> { where(type: 'Booster Pack') },
          class_name: 'MarketAsset', primary_key: :appid, foreign_key: :market_fee_app
  has_many :trading_cards, class_name: 'MarketAsset',
           primary_key: :trading_card_type, foreign_key: :type
  has_many :trading_card_order_histograms, class_name: 'OrderHistogram',
           through: :trading_cards, source: :order_histogram
  has_many :listing_trading_cards, class_name: 'MyListing',
           through: :trading_cards, source: :my_listings

  scope :no_trading_cards, -> { left_outer_joins(:trading_cards).where(market_assets: {type: nil}) }
  scope :unavailable, -> { where(unavailable: true) }
  scope :ppg_order, -> do
    joins(
        <<-SQL
      INNER JOIN "market_assets" 
      ON "market_assets"."type" = "booster_creators"."trading_card_type" 
      INNER JOIN "order_histograms" 
      ON "order_histograms"."item_nameid" = "market_assets"."item_nameid"
      AND "order_histograms"."id" = (
        SELECT oh.id FROM order_histograms oh
        WHERE oh.item_nameid = market_assets.item_nameid
        ORDER BY oh.created_at DESC LIMIT 1
      )
    SQL
    ).group('booster_creators.id').order('1.0 * SUM(order_histograms.lowest_sell_order) / COUNT(order_histograms.id) * 3 / price desc')
  end

  delegate :lowest_sell_order, :highest_buy_order, :lowest_sell_order_exclude_vat, :highest_buy_order_exclude_vat,
           :sell_order_count, :buy_order_count, to: :booster_pack

  class << self
    def refresh_price
      find_each(&:refresh_price_later)
    end

    def scan_all
      find_each(&:scan_market)
    end

    def creatable
      to_a.select do |booster_creator|
        booster_creator.price_per_goo(false) > 0.6
      end
    end
  end

  def trading_card_prices
    trading_card_order_histograms.pluck(:lowest_sell_order, :highest_buy_order).map { |prices| prices.compact.max }.compact
  end

  def trading_card_prices_exclude_vat
    trading_card_prices.map(&Utility.method(:exclude_val))
  end

  def trading_card_prices_proportion
    proportions = trading_card_order_histograms.map(&:proportion).compact
    return nil if proportions.blank?

    proportions.sum / proportions.size
  end

  def open_sell_order_count
    1.0 * trading_card_order_histograms.map(&:sell_order_count).sum / trading_card_prices.count
  end

  def open_buy_order_count
    1.0 * trading_card_order_histograms.map(&:buy_order_count).sum / trading_card_prices.count
  end

  def open_price(include_vat = false)
    prices = include_vat ? trading_card_prices : trading_card_prices_exclude_vat
    average = 1.0 * prices.sum / prices.size
    variance = prices.map { |price| (price - average) ** 2 }.sum / prices.size
    standard_variance = variance ** 0.5
    coefficient_of_variation = standard_variance / average
    {
        total: average * 3,
        variance: variance,
        standard_variance: standard_variance,
        coefficient_of_variation: coefficient_of_variation,
    }
  end

  def open_price_per_goo(include_vat = false)
    prices = include_vat ? trading_card_prices : trading_card_prices_exclude_vat
    return 0 if prices.blank?

    1.0 * prices.sum / prices.size * 3 / price
  end

  def price_per_goo(include_vat = false)
    sell_price = include_vat ? lowest_sell_order : lowest_sell_order_exclude_vat
    return 0 if sell_price.nil?

    1.0 * sell_price / price
  end

  def createable?(ppg = 0.6)
    (price_per_goo > ppg && sell_order_count > 20) ||
        (open_price_per_goo > ppg && open_sell_order_count > 20)
  end

  def listing_trading_card_count
    listing_trading_cards.count
  end

  def sell_proportion
    booster_pack.order_histogram.proportion
  end

  def booster_pack_info
    as_json(
        only: [:appid, :name, :price],
        methods: [
            :price_per_goo, :open_price_per_goo, :open_price, :trading_card_prices_proportion,
            :open_sell_order_count, :open_buy_order_count, :listing_trading_card_count,
            :lowest_sell_order, :sell_order_count, :buy_order_count, :sell_proportion,
        ]
    )
  end

  def scan_market
    Market.scan(appid)
  end

  def refresh_price
    trading_card_order_histograms.each(&:refresh)
  end

  def refresh_price_later
    trading_card_order_histograms.each(&:refresh_later)
  end

  def set_trading_card_type
    self.trading_card_type = "#{name} Trading Card"
  end
end
