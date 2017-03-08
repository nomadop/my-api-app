class ApplicationJob < ActiveJob::Base
  class << self
    def perform_unique(job_class, *args, **option)
      queue = Sidekiq::Queue.new(job_class.queue_name)
      in_queue = queue.any? { |job| job.display_class == job_class.name && job.display_args == args }
      return false if in_queue

      job_class.set(option).perform_later(*args)
    end
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

  rescue_from(SocketError) do
    retry_job
  end

  rescue_from(RestClient::TooManyRequests) do
    puts '429 Too Many Requests, waiting for 5 minutes...'
    sleep 5.minutes
    retry_job
  end
end
