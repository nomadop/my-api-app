class RefreshOrderStatusJob < ApplicationJob
  queue_as :default

  def perform(id)
    buy_order = BuyOrder.find(id)
    buy_order.refresh_status
  end
end
