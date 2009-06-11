$:.unshift "../lib"
require 'eventmachine'
require 'test/unit'

class TestEventMachineCrank < Test::Unit::TestCase
  def setup
    EM.start_crank
  end

  def teardown
    EM.stop_crank
  end

  def test_crank
    count = 0
    EM.next_tick { count += 1 }
    assert_equal 0, count
    EM.crank
    assert_equal 1, count
  end

  def test_crank_until
    count = 0
    EM.add_periodic_timer(0) { count += 1 }
    EM.crank_until { count > 1 }
    assert_equal 2, count
  end

  def test_crank_until_timeout
    count = 0
    EM.add_periodic_timer(0) { count += 1 }
    EM.crank_until(0) { count > 10 }
    assert_equal 1, count
  end
  
  def test_run_machine
    ran = false
    EM.next_tick { ran = true; EM.stop }
    EM.run_machine
    assert ran
  end
end