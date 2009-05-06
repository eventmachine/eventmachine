$:.unshift "../lib"
require 'eventmachine'
require 'test/unit'

class TestInactivityTimeout < Test::Unit::TestCase

  def test_default
    $timeout = nil
    EM.run {
      c = EM.connect("127.0.0.1", 54321)
      $timeout = c.comm_inactivity_timeout
      EM.stop
    }

    assert_equal(0.0, $timeout)
  end

  def test_with_set
    $timeout = nil
    EM.run {
      c = EM.connect("127.0.0.1", 54321)
      c.comm_inactivity_timeout = 2.5
      $timeout = c.comm_inactivity_timeout
      EM.stop
    }

    assert_equal(2.5, $timeout)
  end

end
