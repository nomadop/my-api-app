class QuickBuyJob < ApplicationJob
  queue_as :order_histogram

  def perform(classid, ppg)
    market_asset = MarketAsset.find(classid)
    market_asset.quick_buy(ppg)
  end
end
