class QuickOrderJob < ApplicationJob
  queue_as :quick_buy

  def perform(classid)
    market_asset = MarketAsset.find(classid)
    market_asset.quick_order
  end
end
