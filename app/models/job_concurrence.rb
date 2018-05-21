class JobConcurrence < ApplicationRecord
  enum limit_type: [:block, :throw]

  def increase
    update(concurrence: concurrence + 1)
  end

  def decrease
    update(concurrence: concurrence - 1)
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
