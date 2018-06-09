class TorNewnymJob < ApplicationJob
  queue_as :tor_newnym

  def perform
    JobConcurrence.transaction do
      if JobConcurrence.tor.exists?
        Utility.tor_newnym
        JobConcurrence.tor.destroy_all
      end
    end
    sleep 3.seconds
    TorNewnymJob.perform_later
  end
end
