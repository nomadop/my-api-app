class QuickBuyJob < ApplicationJob
  queue_as :quick_buy

  def perform(classid, ppg)
    market_asset = MarketAsset.find(classid)
    market_asset.quick_buy(ppg)
  end
end
