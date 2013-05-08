require 'em_test_helper'

if EM.ssl?
  class TestSslMinVersion < Test::Unit::TestCase

    module ClientAny
      def connection_completed
        start_tls
      end

      def ssl_handshake_completed
        $client_handshake_completed = true
        close_connection
      end

      def unbind
        EM.stop_event_loop
      end
    end

    module ClientMinV3
      def connection_completed
        start_tls(:min_version => :sslv3)
      end

      def ssl_handshake_completed
        $client_handshake_completed = true
        close_connection
      end

      def unbind
        EM.stop_event_loop
      end
    end

    module ServerMinV3
      def post_init
        start_tls(:min_version => :sslv3)
      end

      def ssl_handshake_completed
        $server_handshake_completed = true
      end
    end

    module ServerTLSv1CaseInsensitive
      def post_init
        start_tls(:min_version => :TLSv1)
      end

      def ssl_handshake_completed
        $server_handshake_completed = true
      end
    end

    module ServerAny
      def post_init
        start_tls
      end

      def ssl_handshake_completed
        $server_handshake_completed = true
      end
    end

    def test_any_to_v3
      $client_handshake_completed, $server_handshake_completed = false, false
      EM.run {
        EM.start_server("127.0.0.1", 16784, ServerMinV3)
        EM.connect("127.0.0.1", 16784, ClientAny)
      }

      assert($client_handshake_completed)
      assert($server_handshake_completed)
    end

    def test_case_insensitivity
      $client_handshake_completed, $server_handshake_completed = false, false
      EM.run {
        EM.start_server("127.0.0.1", 16784, ServerTLSv1CaseInsensitive)
        EM.connect("127.0.0.1", 16784, ClientAny)
      }

      assert($client_handshake_completed)
      assert($server_handshake_completed)
    end

    def test_v3_to_any
      $client_handshake_completed, $server_handshake_completed = false, false
      EM.run {
        EM.start_server("127.0.0.1", 16784, ServerAny)
        EM.connect("127.0.0.1", 16784, ClientMinV3)
      }

      assert($client_handshake_completed)
      assert($server_handshake_completed)
    end

    def test_v3_to_v3
      $client_handshake_completed, $server_handshake_completed = false, false
      EM.run {
        EM.start_server("127.0.0.1", 16784, ServerMinV3)
        EM.connect("127.0.0.1", 16784, ClientMinV3)
      }

      assert($client_handshake_completed)
      assert($server_handshake_completed)
    end

    module ServerV3StopAfterHandshake
      def post_init
        start_tls(:min_version => :sslv3)
      end

      def ssl_handshake_completed
        $server_handshake_completed = true
        EM.stop_event_loop
      end
    end

    module ServerTLSv1StopAfterHandshake
      def post_init
        start_tls(:min_version => :tlsv1)
      end

      def ssl_handshake_completed
        $server_handshake_completed = true
        EM.stop_event_loop
      end
    end

    def test_v3_with_external_client
      $server_handshake_completed = false
      EM.run {
        setup_timeout(2)
        EM.start_server("127.0.0.1", 16784, ServerV3StopAfterHandshake)
        EM.defer {
          require "socket"
          require "openssl"
          sock = TCPSocket.new("127.0.0.1", 16784)
          ctx = OpenSSL::SSL::SSLContext.new
          ctx.ssl_version = :TLSv1_client
          ssl = OpenSSL::SSL::SSLSocket.new(sock, ctx)
          ssl.connect
          ssl.close rescue nil
          sock.close rescue nil
        }
      }

      assert($server_handshake_completed)
    end

    def test_tlsv1_with_external_client
      $server_handshake_completed = false
      EM.run {
        setup_timeout(2)
        EM.start_server("127.0.0.1", 16784, ServerTLSv1StopAfterHandshake)
        EM.defer {
          require "socket"
          require "openssl"
          sock = TCPSocket.new("127.0.0.1", 16784)
          ctx = OpenSSL::SSL::SSLContext.new
          ctx.ssl_version = :TLSv1_client
          ssl = OpenSSL::SSL::SSLSocket.new(sock, ctx)
          ssl.connect
          ssl.close rescue nil
          sock.close rescue nil
        }
      }

      assert($server_handshake_completed)
    end

    def test_tlsv1_required_with_external_client
      $server_handshake_completed = false

      EM.run {
        n = 0
        EM.add_periodic_timer(0.5) {
          n += 1
          (EM.stop rescue nil) if n == 2
        }
        EM.start_server("127.0.0.1", 16784, ServerTLSv1StopAfterHandshake)
        EM.defer {
          require "socket"
          require "openssl"
          sock = TCPSocket.new("127.0.0.1", 16784)
          ctx = OpenSSL::SSL::SSLContext.new
          ctx.ssl_version = :SSLv3_client
          ssl = OpenSSL::SSL::SSLSocket.new(sock, ctx)
          assert_raise OpenSSL::SSL::SSLError do
            ssl.connect
          end
          ssl.close rescue nil
          sock.close rescue nil
          EM.stop rescue nil
        }
      }

      assert(!$server_handshake_completed)
    end
  end
else
  warn "EM built without SSL support, skipping tests in #{__FILE__}"
end
