class TorNewnymJob < ApplicationJob
  queue_as :default

  def perform()
    concurrence = JobConcurrence.find_or_create_by(uuid: 'TorNewnymJob', limit: 1)
    concurrence.with_concurrence { Utility.tor_newnym }
  end

  rescue_from(ActiveRecord::StaleObjectError) do
    false
  end
end
