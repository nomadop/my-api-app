class CancelBuyorderJob < ApplicationJob
  queue_as :cancel_buyorder

  def perform(id, rebuy = false)
    buy_order = BuyOrder.find(id)
    rebuy ? buy_order.rebuy : buy_order.cancel
  end
end
