class ApplicationJob < ActiveJob::Base
  class << self
    def perform_unique(job_class, *args)
      queue = Sidekiq::Queue.new(job_class.queue_name)
      in_queue = queue.any? { |job| job.display_class == job_class.name && job.display_args == args }
      return false if in_queue

      job_class.perform_later(*args)
    end
  end
end
