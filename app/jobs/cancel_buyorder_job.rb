class CancelBuyorderJob < ApplicationJob
  queue_as :cancel_buyorder

  def perform(id, rebuy = false)
    buy_order = BuyOrder.find(id)
    rebuy ? buy_order.rebuy : buy_order.cancel
  end

  rescue_from(ActiveRecord::RecordNotFound) do
    clean_job_concurrence
  end
end
