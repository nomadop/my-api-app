class RebuyPurchasedJob < ApplicationJob
  queue_as :default

  def perform(step = 1, prev_uuid = nil)
    if JobConcurrence.with_in(3.minutes).where(uuid: prev_uuid).exists?
      puts "RebuyPurchasedJob: Step #{step - 1}(#{prev_uuid}) is not finished yet..."
      return retry_job(wait: 1.second)
    end

    uuid = BuyOrder.rebuy_purchased_by_step(step)
    uuid.nil? ?
      RebuyPurchasedJob.set(wait: 5.minutes).perform_later(1, uuid) :
      RebuyPurchasedJob.perform_later(step + 1, uuid)
  end
end
