class TorNewnymJob < ApplicationJob
  queue_as :default

  def perform()
    lock = JobLock.find_by(name: 'TorNewnymJob')
    lock.with_lock { Utility.tor_newnym }
  end

  rescue_from(ActiveRecord::StaleObjectError) do
    false
  end
end
