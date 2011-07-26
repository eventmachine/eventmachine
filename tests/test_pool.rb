class TestPool < Test::Unit::TestCase
  def pool
    @pool ||= EM::Pool.new
  end

  def go
    EM.run { yield }
  end

  def stop
    EM.stop
  end

  def deferrable
    @deferrable ||= EM::DefaultDeferrable.new
  end

  def test_supports_more_work_than_resources
    ran = false
    go do
      pool.perform do
        ran = true
        deferrable
      end
      stop
    end
    assert_equal false, ran
    go do
      pool.add :resource
      stop
    end
    assert_equal true, ran
  end

  def test_reques_resources_on_error
    pooled_res, pooled_res2 = nil
    pool.add :res
    go do
      pool.perform do |res|
        pooled_res = res
        deferrable
      end
      stop
    end
    deferrable.fail
    go do
      pool.perform do |res|
        pooled_res2 = res
        deferrable
      end
      stop
    end
    assert_equal :res, pooled_res
    assert_equal pooled_res, pooled_res2
  end

  def test_supports_custom_error_handler
    eres = nil
    pool.on_error do |res|
      eres = res
    end
    performs = []
    pool.add :res
    go do
      pool.perform do |res|
        performs << res
        deferrable
      end
      pool.perform do |res|
        performs << res
        deferrable
      end
      deferrable.fail
      stop
    end
    assert_equal :res, eres
    # manual requeues required when error handler is installed:
    assert_equal 1, performs.size
    assert_equal :res, performs.first
  end

  def test_catches_successful_deferrables
    performs = []
    pool.add :res
    go do
      pool.perform { |res| performs << res; deferrable }
      pool.perform { |res| performs << res; deferrable }
      stop
    end
    assert_equal [:res], performs
    deferrable.succeed
    go { stop }
    assert_equal [:res, :res], performs
  end

  def test_prunes_locked_and_removed_resources
    performs = []
    pool.add :res
    deferrable.succeed
    go do
      pool.perform { |res| performs << res; pool.remove res; deferrable }
      pool.perform { |res| performs << res; pool.remove res; deferrable }
      stop
    end
    assert_equal [:res], performs
  end

  # Contents is only to be used for inspection of the pool!
  def test_contents
    pool.add :res
    assert_equal [:res], pool.contents
    # Assert that modifying the contents list does not affect the pools
    # contents.
    pool.contents.delete(:res)
    assert_equal [:res], pool.contents
  end

  def test_num_waiting
    pool.add :res
    assert_equal 0, pool.num_waiting
    pool.perform { |r| EM::DefaultDeferrable.new }
    assert_equal 0, pool.num_waiting
    10.times { pool.perform { |r| EM::DefaultDeferrable.new } }
    EM.run { EM.next_tick { EM.stop } }
    assert_equal 10, pool.num_waiting
  end

end