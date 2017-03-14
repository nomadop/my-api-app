class CreateBuyOrderJob < ApplicationJob
  queue_as :create_buy_order

  def perform(classid, method)
    market_asset = MarketAsset.find(classid)
    case method
      when 'quick_create_buy_order'
        market_asset.quick_create_buy_order
      when 'quick_buy'
        market_asset.quick_buy
      else
        return
    end
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
