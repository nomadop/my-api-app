class BoosterCreator < ApplicationRecord
  def booster_pack
    MarketAsset.booster_pack.find_by(name: "#{name} Booster Pack")
  end

  def trading_cards
    MarketAsset.where(type: "#{name} Trading Card")
  end

  def trading_card_prices
    trading_cards.includes(:order_histogram).pluck(:lowest_sell_order).compact
  end

  def trading_card_prices_exclude_vat
    trading_card_prices.map(&Utility.method(:exclude_val))
  end

  def open_price(include_vat = true)
    prices = include_vat ? trading_card_prices : trading_card_prices_exclude_vat
    average = 1.0 * prices.sum / prices.size
    variance = prices.map { |price| (price - average) ** 2 }.sum / prices.size
    standard_variance = variance ** 0.5
    coefficient_of_variation = standard_variance / average
    {
        total: prices.sum,
        variance: variance,
        standard_variance: standard_variance,
        coefficient_of_variation: coefficient_of_variation,
    }
  end

  def price_per_goo(include_vat = true)
    prices = include_vat ? trading_card_prices : trading_card_prices_exclude_vat
    1.0 * prices.sum / price
  end

  def scan_market
    Market.scan(name)
  end
end
