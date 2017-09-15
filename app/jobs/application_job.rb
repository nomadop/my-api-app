class ApplicationJob < ActiveJob::Base
  class << self
    def perform_unique(job_class, *args, **option)
      queue = Sidekiq::Queue.new(job_class.queue_name)
      in_queue = queue.any? { |job| job.display_class == job_class.name && job.display_args == args }
      return false if in_queue

      ss = Sidekiq::ScheduledSet.new
      in_ss = ss.any? { |job| job.display_class == job_class.name && job.display_args == args }
      return false if in_ss

      job_class.set(option).perform_later(*args)
    end
  end

  rescue_from(RestClient::TooManyRequests) do
    puts '429 Too Many Requests, waiting for 5 minutes...'
    sleep 5.minutes
    retry_job
  end
end
