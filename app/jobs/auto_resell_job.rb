class AutoResellJob < ApplicationJob
  queue_as :default

  STEP_NAMES = %w(_ CancelDirty Refresh Reload RefreshPrice CancelCancelable ReloadInventory AutoSell 2FAok)

  def perform(step = 1, prev_uuid = nil)
    job_remains = JobConcurrence.with_in(5.minutes).where(uuid: prev_uuid).count
    if job_remains > 0
      puts "AutoResellJob: Step #{step - 1}(#{STEP_NAMES[step - 1]}) is not finished yet, #{job_remains} jobs left...(#{prev_uuid})"
      return retry_job(wait: 1.second)
    end

    uuid = MyListing.auto_resell_all_by_step(step)
    uuid.nil? ?
      AutoResellJob.set(wait: 30.minutes).perform_later(1, uuid) :
      AutoResellJob.perform_later(step + 1, uuid)
  end
end
