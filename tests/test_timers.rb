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

  def test_restartable_timer
    x = false
    EventMachine.run {
      EventMachine::RestartableTimer.new(0.1) do
        x = true
        EventMachine.stop
      end
    }
    assert x
  end

  def test_add_restartable_timer
    x = false
    EventMachine.run {
      rt = EventMachine.add_restartable_timer(0.1) { x = true }
      assert rt.respond_to?(:restart)
      EventMachine.stop
    }
  end

  def test_restart_restartable_timer
    x = false
    EventMachine.run {
      EventMachine.add_timer(0.4) { x = 1 }
      rt = EventMachine::RestartableTimer.new(0.3) do
        x = true
      end
      EventMachine.add_timer(0.2) { rt.restart }
      EventMachine.add_timer(0.6) { EventMachine.stop }
    }
    assert x == true
  end

  def test_cannot_restart_already_fired_restartable_timer
    x = false
    EventMachine.run {
      rt = EventMachine::RestartableTimer.new(0.1) do
        x = true
      end
      EventMachine.add_timer(0.2) {
        x = false
        rt.restart
      }
      EventMachine.add_timer(0.4) { EventMachine.stop }
    }
    assert !x
  end

  def test_restartable_timer_cancel
    x = false
    EventMachine.run {
      rt = EventMachine::RestartableTimer.new(0.3) { x = true }
      rt.cancel
      EventMachine::Timer.new(0.1) { EventMachine.stop }
    }
    assert !x
  end

  def test_add_restartable_timer_cancel
    x = false
    EventMachine.run {
      rt = EventMachine.add_restartable_timer(0.2) { x = true }
      EventMachine.cancel_timer(rt)
      EventMachine.add_timer(0.3) { EventMachine.stop }
    }
    assert !x
  end

  def test_cannot_restart_cancelled_restartable_timer
    x = false
    EventMachine.run {
      rt = EventMachine::RestartableTimer.new(0.2) do
        x = true
      end
      rt.cancel
      EventMachine.add_timer(0.1) {
        x = false
        rt.restart
      }
      EventMachine.add_timer(0.4) { EventMachine.stop }
    }
    assert !x
  end

end
