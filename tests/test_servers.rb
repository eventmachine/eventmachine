require 'em_test_helper'
require 'socket'

class TestServers < Test::Unit::TestCase

  Host = "127.0.0.1"
  Port = 9555

  def server_alive?(host=Host, port=Port)
    s = TCPSocket.new( host, port )
    s.close
    s
  rescue Errno::ECONNREFUSED
    false
  end

  def run_test_stop_server
    EM.run {
      sig = EM.start_server(Host, Port)
      assert server_alive?, "Server didn't start"
      EM.stop_server sig
      # Give the server some time to shutdown.
      EM.add_timer(0.1) {
        assert !server_alive?, "Server didn't stop"
        EM.stop
      }
    }
  end

  def test_stop_server
    assert !server_alive?, "Port already in use"
    2.times { run_test_stop_server }
    assert !server_alive?, "Servers didn't stop"
  end

end
