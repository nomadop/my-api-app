class CreateBuyOrderJob < ApplicationJob
  queue_as :create_buy_order

  def perform(classid, price, amount)
    market_asset = MarketAsset.find(classid)
    market_asset.create_buy_order(price, amount)
    sleep(2)
  end

  rescue_from(RestClient::Forbidden) do |exception|
    clean_job_concurrence
    ps = Sidekiq::ProcessSet.new
    ps.each do |process|
      next if process['queues'].exclude? 'create_buy_order'

      process.quiet!
      process.stop!
    end
    raise exception
  end
end
