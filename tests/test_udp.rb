require 'em_test_helper'

class TestUDP < Test::Unit::TestCase

  # Open a UDP socket listening in 127.0.0.1 and tries to send a UDP datagram to IP
  # 1.2.3.4 (so no network route). Currently it makes EM to close the UDP socket.
  #   See: https://github.com/eventmachine/eventmachine/issues/276
  def test_udp_no_route
    conn = nil
    @@udp_socket_alive = false
    @@udp_socket_unbind_cause = nil
    @@error_came_in = false

    EM.run do

      conn = EM::open_datagram_socket("127.0.0.1", next_port, EM::Connection) do |c|
        c.send_error_handling = :ERRORHANDLING_REPORT

        def c.unbind cause=nil
          @@udp_socket_unbind_cause = cause
          EM.stop
        end

        def c.receive_senderror(error, data)
          @@error_came_in = (error == Errno::ENETUNREACH) && data == ["1.2.3.4", "5555"]
        end

        c.send_datagram "no-route", "1.2.3.4", 5555
        EM.add_timer(0.2) do
          @@udp_socket_alive = true  unless c.error?
          EM.stop
        end
      end

    end

    assert @@udp_socket_alive, "UDP socket was killed (unbind cause: #{@@udp_socket_unbind_cause})"
    assert @@error_came_in, "No error or incorrect error"
  end

end
