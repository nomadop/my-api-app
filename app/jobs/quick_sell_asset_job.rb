class QuickSellAssetJob < ApplicationJob
  queue_as :default

  def perform(id)
    InventoryAsset.find(id).quick_sell
  rescue Exception => e
    ps = Sidekiq::ProcessSet.new
    ps.each(&:quiet!)
    ps.each(&:stop!)
    raise e
  end
end
