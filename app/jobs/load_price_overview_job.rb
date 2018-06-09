class LoadPriceOverviewJob < ApplicationJob
  queue_as :price_overview

  def perform(market_hash_name)
    Market.load_price_overview(market_hash_name)
  end
end
