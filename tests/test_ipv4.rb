require 'em_test_helper'
require 'socket'

class TestIPv4 < Test::Unit::TestCase

  begin
    socket = Addrinfo.udp("1.2.3.4", 1).connect
    @@local_ipv4 = socket.local_address.ip_address
    socket.close

    # Tries to connect to www.google.com port 80 via TCP.
    # Timeout in 2 seconds.
    def test_ipv4_tcp_client
      conn = nil
      setup_timeout(2)
      
      EM.run do
        conn = EM::connect("www.google.es", 80) do |c|
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
        EM::start_server(@@local_ipv4, @local_port) do |s|
          def s.receive_data data
            @@received_data = data
            EM.stop
          end          
        end

        EM::connect(@@local_ipv4, @local_port) do |c|
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
        EM::open_datagram_socket(@@local_ipv4, @local_port) do |s|
          def s.receive_data data
            @@received_data = data
            EM.stop
          end
        end

        EM::open_datagram_socket(@@local_ipv4, next_port) do |c|
          c.send_datagram "ipv4/udp", @@local_ipv4, @local_port
        end
      end

      assert_equal "ipv4/udp", @@received_data
    end


  rescue => e
    warn "cannot autodiscover local IPv4 (#{e.class}: #{e.message}), skipping tests in #{__FILE__}"

    # Because some rubies will complain if a TestCase class has no tests
    def test_ipv4_unavailable
      assert true
    end

  end

end
