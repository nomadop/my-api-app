class MyListing < ApplicationRecord
  include ActAsListable

  after_create :load_market_asset_later

  has_one :market_asset, primary_key: :market_hash_name, foreign_key: :market_hash_name
  has_one :order_histogram, through: :market_asset

  scope :cancelable, -> { joins(:order_histogram).where('price > order_histograms.lowest_sell_order OR (price > 100 AND price = order_histograms.lowest_sell_order AND CAST(order_histograms.sell_order_graph->0->>1 AS int) - (SELECT COUNT(*) FROM "my_listings" INNER JOIN "market_assets" ON "my_listings"."market_hash_name" = "market_assets"."market_hash_name" WHERE "market_assets"."item_nameid" = order_histograms.item_nameid) > 0)') }

  delegate :load_order_histogram, :find_sell_balance, :goo_value, to: :market_asset
  delegate :lowest_sell_order, to: :order_histogram

  class << self
    def reload(start = 0, count = 100)
      result = Market.request_my_listings(start, count)
      return false unless result['success']

      Market.handle_my_listing_result(result)
      tail = start + count
      reload(tail, count) if tail < result['total_count']
    end

    def reload!
      destroy_all
      reload
    end

    def refresh_order_histogram
      includes(:market_asset).find_each(&:load_order_histogram)
    end
  end

  def cancelable?
    price > order_histogram.lowest_sell_order ||
        (price > 100 && price == order_histogram.lowest_sell_order && order_histogram.sell_order_graph[0][1] > 1)
  end

  def sell_balance(with_in: 1.week)
    market_asset.sell_balance(price, with_in: with_in)
  end

  def price_exclude_vat
    Utility.exclude_val(price)
  end

  def price_per_goo_exclude_vat
    return Float::INFINITY if price.nil? || goo_value.nil?

    1.0 * price_exclude_vat / goo_value
  end

  def cancel
    Market.cancel_my_listing(listingid)
  end

  def load_market_asset_later
    ApplicationJob.perform_unique(LoadMarketAssetJob, nil, market_hash_name) if market_asset.nil?
  end
end
