class LoadMarketAssetJob < ApplicationJob
  queue_as :default

  def perform(market_hash_name)
    Market.load_asset(market_hash_name)
  rescue Exception => e
    puts [e.inspect, e.backtrace]
    ps = Sidekiq::ProcessSet.new
    ps.each(&:stop!)
  end
end
