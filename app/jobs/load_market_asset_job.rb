class LoadMarketAssetJob < ApplicationJob
  queue_as :low

  def perform(market_hash_name)
    Market.load_asset_by_hash_name(market_hash_name)
  rescue Exception => e
    ps = Sidekiq::ProcessSet.new
    ps.each(&:quiet!)
    ps.each(&:stop!)
    raise e
  end
end
