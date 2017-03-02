class QuickSellAssetJob < ApplicationJob
  queue_as :default

  def perform(id)
    InventoryAsset.find(id).quick_sell
  end
end
