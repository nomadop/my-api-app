class JobLock < ApplicationRecord
  def lock!
    update(locked: true)
  end

  def unlock!
    update(locked: false)
  end

  def with_lock
    return if locked
    lock!
    yield
    unlock!
  end
end
