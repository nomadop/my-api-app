class CreateBuyOrderJob < ApplicationJob
  queue_as :create_buy_order

  def perform(classid)
    market_asset = MarketAsset.find(classid)
    market_asset.quick_create_buy_order
  end

  rescue_from(RestClient::Forbidden) do |exception|
    ps = Sidekiq::ProcessSet.new
    ps.each do |process|
      next if process['queues'].exclude? 'create_buy_order'

      process.quiet!
      process.stop!
    end
    raise exception
  end
end
