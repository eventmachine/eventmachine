require 'em_test_helper'

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

end
