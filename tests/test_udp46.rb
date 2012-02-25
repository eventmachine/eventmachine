require 'em_test_helper'

class TestUDP46 < Test::Unit::TestCase

  # this is a bit brittle.  Maybe do not test for the actual error...
  WANT_ALL = [
              ( RUBY_PLATFORM =~ /darwin1/ and # not an error in Linux (!?),
                # strange handling in OSX 10.5.x (darwin9)
                ["::1", "::241.1.2.3", 5555, Errno::EHOSTUNREACH]),
              ["::1", "241.2.3.4", 5555,
               (RUBY_PLATFORM =~ /linux/ ? Errno::ENETUNREACH : Errno::EINVAL)],
              ["127.0.0.1", "241.4.5.6", 5555,
               (RUBY_PLATFORM =~ /linux/ ? Errno::EINVAL : Errno::ENETUNREACH)]
             ].compact

  # Open a UDP socket listening on, say, ::1, and try to send a UDP
  # datagram to IP address, say, ::241.1.2.3 (so no network route).
  # Without the error handling fix, it makes EM close the UDP socket.
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
