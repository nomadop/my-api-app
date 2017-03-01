class LoadMarketAssetJob < ApplicationJob
  queue_as :low

  def perform(option)
    return Market.load_asset_by_hash_name(option[:market_hash_name]) if option[:market_hash_name]

    market_search_result = MarketSearchResult.find(option[:market_search_result_id])
    market_search_result.load_market_asset
  rescue Exception => e
    ps = Sidekiq::ProcessSet.new
    ps.each(&:quiet!)
    ps.each(&:stop!)
    raise e
  end
end
