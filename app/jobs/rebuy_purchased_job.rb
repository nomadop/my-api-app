class RebuyPurchasedJob < ApplicationJob
  queue_as :default

  def perform()
    BuyOrder.rebuy_purchased
    RebuyPurchasedJob.set(wait: 5.minutes).perform_later
  end
end
