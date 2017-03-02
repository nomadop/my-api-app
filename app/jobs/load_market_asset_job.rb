class LoadMarketAssetJob < ApplicationJob
  queue_as :low

  def perform(option)
    Market.load_asset_by_url(option[:url]) if option[:url]
    Market.load_asset_by_hash_name(option[:market_hash_name]) if option[:market_hash_name]
  rescue Exception => e
    ps = Sidekiq::ProcessSet.new
    ps.each(&:quiet!)
    ps.each(&:stop!)
    raise e
  end
end
