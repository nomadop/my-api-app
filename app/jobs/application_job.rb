class ApplicationJob < ActiveJob::Base
  class << self
    def perform_unique(job_class, *args)
      queue = Sidekiq::Queue.new(job_class.queue_name)
      in_queue = queue.any? { |job| job.display_class == job_class.name && job.display_args == args }
      return false if in_queue

      job_class.perform_later(*args)
    end
  end

  rescue_from(RestClient::TooManyRequests) do
    '429 Too Many Requests, waiting for 3 minutes...'
    sleep 3.minutes
    retry_job
  end

  rescue_from(Exception) do |exception|
    ps = Sidekiq::ProcessSet.new
    ps.each do |process|
      next if process['queues'].exclude? self.class.queue_name

      process.quiet!
      process.stop!
    end
    raise exception
  end
end
