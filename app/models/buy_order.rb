class BuyOrder < ApplicationRecord
  after_create :refresh_status_later

  def refresh_status
    status = Market.get_buy_order_status(buy_orderid)
    update(status)
  end

  def refresh_status_later
    ApplicationJob.perform_unique(RefreshOrderStatusJob, id, wait: 1.seconds)
  end
end
