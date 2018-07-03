class JobConcurrence < ApplicationRecord
  class JobNotComplete < Exception; end

  scope :tor, ->(instance = nil) { where('uuid like ?', "#{TOR.concurrence_uuid(instance)}%") }
  scope :with_in, ->(duration) { where('created_at > ?', duration.ago) }
  scope :not_delegated, -> { where(delegated: false) }

  enum limit_type: [:block, :throw]

  class << self
    def start(uuid = SecureRandom.uuid, limit = nil)
      raise 'no block given' unless block_given?

      jobs = Array(yield).select { |job| job.is_a?(ApplicationJob) }
      concurrences = jobs.map { |job| {uuid: uuid, limit: limit, job_id: job.job_id} }
      JobConcurrence.import(concurrences)
      uuid
    end

    def wait_for(uuid, sleep_time: 3.second, timeout: nil)
      return if uuid.nil?

      wait_time = 0.second
      loop do
        sleep sleep_time
        return unless where(uuid: uuid).exists?
        wait_time += sleep_time
        raise 'timeout' if timeout && wait_time > timeout
      end
    end

    def start_and_wait_for(uuid = SecureRandom.uuid, limit = nil, sleep_time: 3.second, timeout: nil, &block)
      raise 'no block given' unless block_given?

      start(uuid, limit, &block)
      wait_for(uuid, sleep_time: sleep_time, timeout: timeout)
    end

    def tor_newnym(instance = nil)
      JobConcurrence.create(uuid: TOR.concurrence_uuid(instance), limit: 1)
    rescue ActiveRecord::RecordNotUnique
      return
    end

    def clean(uuid)
      where(uuid: uuid).delete_all
    end
  end
end
