class TorNewnymJob < ApplicationJob
  queue_as :tor_newnym

  def perform
    JobConcurrence.tor.not_delegated.find_each do |job_concurrence|
      instance = TOR.extract_instance(job_concurrence.uuid)
      if instance.nil?
        Utility.tor_newnym
        job_concurrence.destroy
      else
        DelegateJob.perform_later('TOR', 'new_nym', instance)
        job_concurrence.update(delegated: true)
      end
    end
    sleep 3.seconds
    TorNewnymJob.perform_later
  end
end
