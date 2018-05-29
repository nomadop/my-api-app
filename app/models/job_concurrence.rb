class JobConcurrence < ApplicationRecord
  enum limit_type: [:block, :throw]

  class << self
    def start(uuid = SecureRandom.uuid, limit = nil)
      raise 'no block given' unless block_given?

      jobs = yield
      jobs = [jobs] unless jobs.is_a?(Array)
      concurrences = jobs.map { |job| {uuid: uuid, limit: limit, job_id: job.job_id} }
      JobConcurrence.import(concurrences)
      uuid
    end

    def wait_for(uuid, sleep_time: 3.second, timeout: nil)
      wait_time = 0.second
      loop do
        sleep sleep_time
        return unless where(uuid: uuid).exists?
        wait_time += sleep_time
        raise 'timeout' if timeout && wait_time > timeout
      end
    end
  end
end
