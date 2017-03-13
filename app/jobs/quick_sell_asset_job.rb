class QuickSellAssetJob < ApplicationJob
  queue_as :quick_sell

  def perform(id)
    InventoryAsset.find(id).quick_sell
  end

  rescue_from(RestClient::BadGateway) do
    puts 'Sell item failed...'
    false
  end
end
