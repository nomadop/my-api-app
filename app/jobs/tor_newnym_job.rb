class TorNewnymJob < ApplicationJob
  queue_as :default

  def perform()
    JobConcurrence.create(uuid: 'TorNewnymJob', limit: 1, job_id: @job_id)
    Utility.tor_newnym
  end

  rescue_from(ActiveRecord::RecordNotUnique) do
    clean_job_concurrence
  end
end
