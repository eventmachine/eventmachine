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

  module Client
    def connection_completed
      EM.next_tick{
        $client_connected = EM.connection_count
        EM.stop
      }
    end
  end

  module Server
    def post_init
      $server_connected = EM.connection_count
    end
  end

  def test_with_some_connections
    EM.run {
      $initial = EM.connection_count
      EM.start_server("127.0.0.1", 9999, Server)
      $server_started = EM.connection_count
      EM.next_tick{
        EM.connect("127.0.0.1", 9999, Client)
      }
    }

    assert_equal(0, $initial)
    assert_equal(1, $server_started)
    assert_equal(2, $server_connected)
    assert_equal(3, $client_connected)
  end
end