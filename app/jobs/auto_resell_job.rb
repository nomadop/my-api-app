class AutoResellJob < ApplicationJob
  queue_as :default

  def perform(step = 1, prev_uuid = nil)
    if JobConcurrence.where(uuid: prev_uuid).exists?
      puts "AutoResellJob: Step #{step - 1}(#{prev_uuid}) is not finished yet..."
      return retry_job(wait: 1.second)
    end

    uuid = MyListing.auto_resell_all_by_step(step)
    uuid.nil? ?
      AutoResellJob.set(wait: 30.minutes).perform_later(1, uuid) :
      AutoResellJob.perform_later(step + 1, uuid)
  end
end
