require 'em_test_helper'

class TestUDP46 < Test::Unit::TestCase

  WANT_ALL = [["::1", "::241.2.3.4", 5555, Errno::EHOSTUNREACH],
              ["127.0.0.1", "241.2.3.4", 5555, Errno::ENETUNREACH]
             ]

  # Open a UDP socket listening in ::1 and tries to send a UDP datagram to IP
  # ::241.1.2.3 (so no network route). Currently it makes EM to close the UDP socket.
  #   See: https://github.com/eventmachine/eventmachine/issues/276
  def test_udp_no_route
    WANT_ALL.each do |want|
      @@udp_socket_alive = false
      @@udp_socket_unbind_cause = nil
      @@error_came_in = false

      EM.run do

        EM::open_datagram_socket(want[0], next_port, EM::Connection) do |c|
          c.send_error_handling = :ERRORHANDLING_REPORT

          def c.unbind cause=nil
            @@udp_socket_unbind_cause = cause
            EM.stop
          end

          def c.receive_senderror(error, data)
            @@error_came_in = [error, data]
          end

          c.send_datagram "no-route", want[1], want[2]
          EM.add_timer(0.2) do
            @@udp_socket_alive = true  unless c.error?
            EM.stop
          end
        end

      end

      assert @@udp_socket_alive, "UDP socket was killed (unbind cause: #{@@udp_socket_unbind_cause})"
      assert_equal [want[3], [want[1], want[2].to_s]], @@error_came_in

    end
  end
end
