class TorNewnymJob < ApplicationJob
  queue_as :tor_newnym

  def perform(port)
    JobConcurrence.tor.not_delegated.find_each do |job_concurrence|
      port = TOR.extract_instance(job_concurrence.uuid)
      if port.nil?
        Utility.tor_newnym
        job_concurrence.destroy
      else
        DelegateJob.perform_later('TOR', 'new_nym', port)
        TOR.log(port.to_s, 'new nym job delegated', :warning)
        job_concurrence.update(delegated: true)
      end
    end
    TorNewnymJob.set(wait: 3.seconds).perform_later
  end
end
