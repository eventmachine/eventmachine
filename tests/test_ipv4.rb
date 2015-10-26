require 'em_test_helper'
require 'socket'

class TestIPv4 < Test::Unit::TestCase

  if Test::Unit::TestCase.public_ipv4?

    # Tries to connect to www.google.com port 80 via TCP.
    # Timeout in 2 seconds.
    def test_ipv4_tcp_client
      conn = nil
      setup_timeout(2)

      EM.run do
        conn = EM::connect("www.google.com", 80) do |c|
          def c.connected
            @connected
          end

          def c.connection_completed
            @connected = true
            EM.stop
          end
        end
      end

      assert conn.connected
    end

    # Runs a TCP server in the local IPv4 address, connects to it and sends a specific data.
    # Timeout in 2 seconds.
    def test_ipv4_tcp_local_server
      @@received_data = nil
      @local_port = next_port
      setup_timeout(2)

      EM.run do
        EM::start_server(@@public_ipv4, @local_port) do |s|
          def s.receive_data data
            @@received_data = data
            EM.stop
          end
        end

        EM::connect(@@public_ipv4, @local_port) do |c|
          c.send_data "ipv4/tcp"
        end
      end

      assert_equal "ipv4/tcp", @@received_data
    end

    # Runs a UDP server in the local IPv4 address, connects to it and sends a specific data.
    # Timeout in 2 seconds.
    def test_ipv4_udp_local_server
      @@received_data = nil
      @local_port = next_port
      setup_timeout(2)

      EM.run do
        EM::open_datagram_socket(@@public_ipv4, @local_port) do |s|
          def s.receive_data data
            @@received_data = data
            EM.stop
          end
        end

        EM::open_datagram_socket(@@public_ipv4, next_port) do |c|
          c.send_datagram "ipv4/udp", @@public_ipv4, @local_port
        end
      end

      assert_equal "ipv4/udp", @@received_data
    end

    # Try to connect via TCP to an invalid IPv4. EM.connect should raise
    # EM::ConnectionError.
    def test_tcp_connect_to_invalid_ipv4
      invalid_ipv4 = "9.9:9"

      EM.run do
        begin
          error = nil
          EM.connect(invalid_ipv4, 1234)
        rescue => e
          error = e
        ensure
          EM.stop
          assert_equal EM::ConnectionError, (error && error.class)
        end
      end
    end

    # Try to send a UDP datagram to an invalid IPv4. EM.send_datagram should raise
    # EM::ConnectionError.
    def test_udp_send_datagram_to_invalid_ipv4
      invalid_ipv4 = "9.9:9"

      EM.run do
        begin
          error = nil
          EM.open_datagram_socket(@@public_ipv4, next_port) do |c|
            c.send_datagram "hello", invalid_ipv4, 1234
          end
        rescue => e
          error = e
        ensure
          EM.stop
          assert_equal EM::ConnectionError, (error && error.class)
        end
      end
    end


  else
    warn "no IPv4 in this host, skipping tests in #{__FILE__}"

    # Because some rubies will complain if a TestCase class has no tests
    def test_ipv4_unavailable
      assert true
    end

  end

end
