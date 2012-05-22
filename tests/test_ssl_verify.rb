require 'em_test_helper'

if EM.ssl?
  class TestSslVerify < Test::Unit::TestCase
    CERT_DIRECTORY = File.expand_path("../certs", __FILE__) + '/'
    CLIENT_KEY_FILE  = CERT_DIRECTORY + 'client.key'
    CLIENT_CERT_FILE = CERT_DIRECTORY + 'client.crt'

    def cert_from_file
      File.read(CLIENT_CERT_FILE)
    end

    module Client
      def connection_completed
        start_tls(:private_key_file => CLIENT_KEY_FILE, :cert_chain_file => CLIENT_CERT_FILE)
      end

      def ssl_handshake_completed
        $client_handshake_completed = true
        close_connection
      end

      def unbind
        EM.stop_event_loop
      end
    end

    module AcceptServer
      def post_init
        start_tls(:verify_peer => true)
      end

      def ssl_verify_peer(cert)
        $cert_from_server = cert
        true
      end

      def ssl_handshake_completed
        $server_handshake_completed = true
      end
    end

    module DenyServer
      def post_init
        start_tls(:verify_peer => true)
      end

      def ssl_verify_peer(cert)
        $cert_from_server = cert
        # Do not accept the peer. This should now cause the connection to shut down without the SSL handshake being completed.
        false
      end

      def ssl_handshake_completed
        $server_handshake_completed = true
      end
    end

    def test_accept_server
      $client_handshake_completed, $server_handshake_completed = false, false
      EM.run {
        EM.start_server("127.0.0.1", 16784, AcceptServer)
        EM.connect("127.0.0.1", 16784, Client)
      }

      assert_equal(cert_from_file, $cert_from_server)
      assert($client_handshake_completed)
      assert($server_handshake_completed)
    end

    def test_deny_server
      $client_handshake_completed, $server_handshake_completed = false, false
      EM.run {
        EM.start_server("127.0.0.1", 16784, DenyServer)
        EM.connect("127.0.0.1", 16784, Client)
      }

      assert_equal(cert_from_file, $cert_from_server)
      assert(!$client_handshake_completed)
      assert(!$server_handshake_completed)
    end
  end
else
  warn "EM built without SSL support, skipping tests in #{__FILE__}"
end
