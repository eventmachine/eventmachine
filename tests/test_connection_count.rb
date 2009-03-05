$:.unshift "../lib"
require 'eventmachine'
require 'test/unit'

class TestConnectionCount < Test::Unit::TestCase

  def test_idle_connection_count
    EM.run {
      $count = EM.connection_count
      EM.stop_event_loop
    }

    assert_equal(0, $count)
  end

  def test_with_some_connections
    EM.run {
      EM.start_server("127.0.0.1", 9999)
      EM.connect("127.0.0.1", 9999)
      $first_tick = EM.connection_count
      EM.next_tick { 
        $second_tick = EM.connection_count
        EM.next_tick { 
          $third_tick = EM.connection_count
          EM.stop_event_loop 
        } 
      }
    }

    assert_equal(0, $first_tick)
    assert_equal(2, $second_tick)
    assert_equal(3, $third_tick)
  end

end