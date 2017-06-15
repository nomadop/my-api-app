class AutoRebuyJob < ApplicationJob
  queue_as :auto_rebuy

  def perform(id)
    buy_order = BuyOrder.find(id)
    buy_order.auto_rebuy
  end
end
