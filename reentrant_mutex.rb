class ReentrantMutex < Mutex
  def initialize
    @count_mutex = Mutex.new
    @counts      = Hash.new(0)

    super
  end

  def synchronize
    raise ThreadError, 'Must be called with a block' unless block_given?

    begin
      lock
      yield
    ensure
      unlock
    end
  end

  def lock
    c = increase_count Thread.current
    super if c <= 1
    self
  end

  def unlock
    c = decrease_count Thread.current
    if c <= 0
      super
      delete_count Thread.current
    end
    self
  end

  def try_lock
    if owned?
      lock
      return true
    else
      ok = super
      increase_count Thread.current if ok
      return ok
    end
  end

  private

  def increase_count(thread)
    @count_mutex.synchronize { @counts[thread] += 1 }
  end

  def decrease_count(thread)
    @count_mutex.synchronize { @counts[thread] -= 1 }
  end

  def delete_count(thread)
    @count_mutex.synchronize { @counts.delete(thread) }
  end
end