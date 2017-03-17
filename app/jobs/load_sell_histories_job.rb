class LoadSellHistoriesJob < ApplicationJob
  queue_as :load_histories

  def perform(classid)
    market_asset = MarketAsset.find(classid)
    market_asset.load_sell_histories
  end
end
