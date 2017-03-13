class BuyOrder < ApplicationRecord
  def refresh_status
    status = Market.get_buy_order_status(buy_orderid)
    update(status)
  end
end
