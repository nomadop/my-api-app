class ApplicationJob < ActiveJob::Base
  class << self
    def perform_unique(job_class, *args, **option)
      queue = Sidekiq::Queue.new(job_class.queue_name)
      in_queue = queue.any? { |job| job.display_class == job_class.name && job.display_args == args }
      return false if in_queue

      ss = Sidekiq::ScheduledSet.new
      in_ss = ss.any? { |job| job.display_class == job_class.name && job.display_args == args }
      return false if in_ss

      workers = Sidekiq::Workers.new
      in_work = workers.any? do |_, _, work|
        work_args = work['payload']['args'][0]
        work_args['job_class'] == job_class.name && work_args['arguments'] == args
      end
      return false if in_work

      job_class.set(option).perform_later(*args)
    end
  end

  rescue_from(RestClient::TooManyRequests) do
    puts '429 Too Many Requests, waiting for 5 minutes...'
    sleep 5.minutes
    retry_job
  end
end
