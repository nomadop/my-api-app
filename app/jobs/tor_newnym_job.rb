class TorNewnymJob < ApplicationJob
  queue_as :tor_newnym

  def perform
    JobConcurrence.transaction do
      if JobConcurrence.tor.exists?
        Utility.tor_newnym
        JobConcurrence.tor.destroy_all
      end
    end
    TorNewnymJob.set(wait: 3.seconds).perform_later
  end
end
