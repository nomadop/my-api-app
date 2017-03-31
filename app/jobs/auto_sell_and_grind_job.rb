class AutoSellAndGrindJob < ApplicationJob
  queue_as :quick_sell

  def perform(id)
    asset = InventoryAsset.find(id)
    asset.auto_sell_and_grind
  end

  rescue_from(RestClient::BadGateway) do
    puts 'Sell item failed...'
    false
  end
end
