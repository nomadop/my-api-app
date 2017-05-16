module ActAsBoosterPack
  extend ActiveSupport::Concern

  included do
    has_one :booster_creator, primary_key: :market_fee_app, foreign_key: :appid
    has_many :trading_cards, through: :booster_creator
    has_many :trading_card_order_histograms, class_name: 'OrderHistogram',
             through: :trading_cards, source: :order_histogram
    has_many :listing_trading_cards, class_name: 'MyListing',
             through: :trading_cards, source: :my_listings

    scope :no_trading_cards, -> { left_outer_joins(:trading_cards).where(trading_cards_market_assets: {type: nil}) }
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

  def buyable?
    lowest_sell_order < open_price[:total] && open_price[:coefficient_of_variation] < 1 && open_sell_order_count > 20
  end

  def listing_trading_card_count
    listing_trading_cards.count
  end

  def booster_pack_info
    as_json(
        only: [:appid, :name, :price],
        methods: [
            :open_price, :trading_card_prices_proportion, :open_sell_order_count, :open_buy_order_count,
            :listing_trading_card_count, :sell_order_count, :buy_order_count
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
end