require 'em_test_helper'

if EM.ssl?
  class TestSslV3Only < Test::Unit::TestCase

    module ClientV23
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

    module ClientV3
      def connection_completed
        start_tls(:force_ssl_v3 => true)
      end

      def ssl_handshake_completed
        $client_handshake_completed = true
        close_connection
      end

      def unbind
        EM.stop_event_loop
      end
    end

    module ServerV3
      def post_init
        start_tls(:force_ssl_v3 => true)
      end

      def ssl_handshake_completed
        $server_handshake_completed = true
      end
    end

    module ServerV23
      def post_init
        start_tls
      end

      def ssl_handshake_completed
        $server_handshake_completed = true
      end
    end

    def test_v23_to_v3
      $client_handshake_completed, $server_handshake_completed = false, false
      EM.run {
        EM.start_server("127.0.0.1", 16784, ServerV3)
        EM.connect("127.0.0.1", 16784, ClientV23)
      }

      assert(!$client_handshake_completed)
      assert(!$server_handshake_completed)
    end

    def test_v3_to_v23
      $client_handshake_completed, $server_handshake_completed = false, false
      EM.run {
        EM.start_server("127.0.0.1", 16784, ServerV23)
        EM.connect("127.0.0.1", 16784, ClientV3)
      }

      assert($client_handshake_completed)
      assert($server_handshake_completed)
    end

    def test_v3_to_v3
      $client_handshake_completed, $server_handshake_completed = false, false
      EM.run {
        EM.start_server("127.0.0.1", 16784, ServerV3)
        EM.connect("127.0.0.1", 16784, ClientV3)
      }

      assert($client_handshake_completed)
      assert($server_handshake_completed)
    end
  end
else
  warn "EM built without SSL support, skipping tests in #{__FILE__}"
end
