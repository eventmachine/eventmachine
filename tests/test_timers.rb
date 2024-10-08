require_relative 'em_test_helper'

class TestTimers < Test::Unit::TestCase

  def test_timer_with_block
    x = false
    EM.run {
      EM::Timer.new(0) {
        x = true
        EM.stop
      }
    }
    assert x
  end

  def test_timer_with_proc
    x = false
    EM.run {
      EM::Timer.new(0, proc {
        x = true
        EM.stop
      })
    }
    assert x
  end

  def test_timer_cancel
    assert_nothing_raised do
      EM.run {
        timer = EM::Timer.new(0.01) { flunk "Timer was not cancelled." }
        timer.cancel

        EM.add_timer(0.02) { EM.stop }
      }
    end
  end

  def test_periodic_timer
    x = 0
    EM.run {
      EM::PeriodicTimer.new(0.01) do
        x += 1
        EM.stop if x == 4
      end
    }

    assert_equal 4, x
  end

  def test_add_periodic_timer
    x = 0
    EM.run {
      t = EM.add_periodic_timer(0.01) do
        x += 1
        EM.stop  if x == 4
      end
      assert t.respond_to?(:cancel)
    }
    assert_equal 4, x
  end

  def test_periodic_timer_cancel
    x = 0
    EM.run {
      pt = EM::PeriodicTimer.new(0.01) { x += 1 }
      pt.cancel
      EM::Timer.new(0.02) { EM.stop }
    }
    assert_equal 0, x
  end

  def test_add_periodic_timer_cancel
    x = 0
    EM.run {
      pt = EM.add_periodic_timer(0.01) { x += 1 }
      EM.cancel_timer(pt)
      EM.add_timer(0.02) { EM.stop }
    }
    assert_equal 0, x
  end

  def test_periodic_timer_self_cancel
    x = 0
    EM.run {
      pt = EM::PeriodicTimer.new(0) {
        x += 1
        if x == 4
          pt.cancel
          EM.stop
        end
      }
    }
    assert_equal 4, x
  end

  def test_oneshot_timer_large_future_value
    large_value = 11948602000
    EM.run {
      EM.add_timer(large_value) { EM.stop }
      EM.add_timer(0.02) { EM.stop }
    }
  end

  def test_add_timer_increments_timer_count
    pend('FIXME: this test is broken in pure ruby mode') if pure_ruby_mode?
    EM.run {
      n = EM.get_timer_count
      EM::Timer.new(0.01) {
        EM.stop
      }
      assert_equal(n+1, EM.get_timer_count)
    }
  end

  def test_timer_run_decrements_timer_count
    pend('FIXME: this test is broken in pure ruby mode') if pure_ruby_mode?
    EM.run {
      n = EM.get_timer_count
      EM::Timer.new(0.01) {
        assert_equal(n, EM.get_timer_count)
        EM.stop
      }
    }
  end

  # This test is only applicable to compiled versions of the reactor.
  # Pure ruby and java versions have no built-in limit on the number of outstanding timers.
  def test_timer_change_max_outstanding
    omit_if jruby?
    pend('FIXME: this test is broken in pure ruby mode') if pure_ruby_mode?
    defaults = EM.get_max_timers
    EM.set_max_timers(100)

    one_hundred_one_timers = lambda do
      101.times { EM.add_timer(0.01) {} }
      EM.stop
    end

    assert_raises(RuntimeError) do
      EM.run( &one_hundred_one_timers )
    end

    EM.set_max_timers( 101 )

    assert_nothing_raised do
      EM.run( &one_hundred_one_timers )
    end
  ensure
    EM.set_max_timers(defaults)
  end

end
