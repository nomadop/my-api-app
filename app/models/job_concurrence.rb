class JobConcurrence < ApplicationRecord
  enum limit_type: [:block, :throw]

  class << self
    def start(uuid = nil)
      raise 'no block given' unless block_given?

      concurrence = create(uuid: uuid || SecureRandom.uuid)
      yield(concurrence.uuid)
      concurrence.uuid
    end

    def wait_for(uuid)
      concurrence = find_by(uuid: uuid)
      return if concurrence.nil?

      down_time = 0.second
      sleep_time = 0.5.second
      loop do
        sleep sleep_time
        down_time = concurrence.reload.completed? ? down_time + sleep_time : 0.second
        break if down_time > 3.second
      end
    end

    def with_concurrence(uuid = nil, &block)
      raise 'no block given' unless block_given?

      return yield if uuid.nil?

      concurrence = find_by(uuid: uuid)
      concurrence.with_concurrence(&block)
    end
  end

  def increase
    reload.update(concurrence: concurrence + 1)
  rescue ActiveRecord::StaleObjectError
    sleep 0.1.second
    increase
  end

  def decrease
    reload.update(concurrence: concurrence - 1)
  rescue ActiveRecord::StaleObjectError
    sleep 0.1.second
    decrease
  end

  def limited?
    limit > 0 && concurrence >= limit
  end

  def completed?
    concurrence <= 0
  end

  def with_concurrence
    raise 'no block given' unless block_given?
    if limited?
      return if block?
      raise 'limit reached' if throw?
    end
    increase
    yield
    decrease
  end
end
