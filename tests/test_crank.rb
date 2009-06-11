$:.unshift "../lib"
require 'eventmachine'
require 'test/unit'

class TestEventMachineCrank < Test::Unit::TestCase
  def test_crank
    count = 0
    EM.start_crank

    EM.add_periodic_timer(0) { count += 1 }
    assert_equal 0, count
    EM.crank
    assert_equal 1, count
    EM.crank
    assert_equal 2, count

    EM.stop_crank
  end
end