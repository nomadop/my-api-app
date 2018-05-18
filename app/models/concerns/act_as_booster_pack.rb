module ActAsBoosterPack
  extend ActiveSupport::Concern

  class_methods do
    def register_asset_type(type, &block)
      type_str = type.to_s
      relation_proc = block_given? ? block : -> do
        where('type like ?', "%#{type_str.titleize}")
      end
      relation_sym = type_str.pluralize.to_sym
      order_histogram_relation_sym = "#{type}_order_histograms".to_sym
      has_many relation_sym, relation_proc, class_name: 'MarketAsset',
               primary_key: :market_fee_app, foreign_key: :market_fee_app
      has_many order_histogram_relation_sym, class_name: 'OrderHistogram',
               through: relation_sym, source: :order_histogram
      define_method("#{type}_prices") do
        send(order_histogram_relation_sym).pluck(:lowest_sell_order, :highest_buy_order).map { |prices| prices.compact.max }.compact
      end
      define_method("#{type}_prices_exclude_vat") do
        send("#{type}_prices").map(&Utility.method(:exclude_val))
      end
    end
  end

  included do
    has_one :booster_creator, primary_key: :market_fee_app, foreign_key: :appid
    has_many :listing_trading_cards, class_name: 'MyListing',
             through: :trading_cards, source: :my_listings
    scope :no_trading_cards, -> { left_outer_joins(:trading_cards).where(trading_cards_market_assets: {type: nil}) }

    register_asset_type(:trading_card) do
      where('type like ?', '%Trading Card').where.not('type like ?', '%Foil Trading Card')
    end
    register_asset_type(:foil_trading_card)
    register_asset_type(:profile_background) do
      where('type like ?', '%Profile Background')
        .where.not('type like ?', '%Rare Profile Background')
        .where.not('type like ?', '%Uncommon Profile Background')
    end
    register_asset_type(:rare_profile_background)
    register_asset_type(:uncommon_profile_background)
    register_asset_type(:emoticon) do
      where('type like ?', '%Emoticon')
        .where.not('type like ?', '%Rare Emoticon')
        .where.not('type like ?', '%Uncommon Emoticon')
    end
    register_asset_type(:rare_emoticon)
    register_asset_type(:uncommon_emoticon)
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
    return nil if prices.blank?

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
    return false if lowest_sell_order.nil? || trading_card_prices_exclude_vat.blank?
    min_price = trading_card_prices_exclude_vat.min || 0
    lowest_sell_order < min_price * 3
  end

  def listing_trading_card_count
    listing_trading_cards.count
  end

  def listing_booster_pack_count
    my_listings.count
  end

  def sell_proportion
    order_histogram&.proportion || 0
  end

  def booster_pack_info_without_price
    as_json(
        only: [:market_hash_name],
        methods: [
            :open_price, :trading_card_prices_proportion, :open_sell_order_count, :open_buy_order_count,
            :listing_trading_card_count, :listing_booster_pack_count,
            :sell_order_count, :buy_order_count, :sell_proportion, :highest_buy_order, :lowest_sell_order,
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