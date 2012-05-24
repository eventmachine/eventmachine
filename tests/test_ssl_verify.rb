require 'em_test_helper'

if EM.ssl?
  class TestSslVerify < Test::Unit::TestCase
    CERT_DIRECTORY = File.expand_path("../certs", __FILE__) + '/'
    CLIENT_KEY_FILE  = CERT_DIRECTORY + 'client.key'
    CLIENT_CERT_FILE = CERT_DIRECTORY + 'client.crt'
    AUTHORITATIVE_CACERT = File.expand_path('../../cacert.pem', __FILE__)

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

    module WebClient
      def post_init
        start_tls(:verify_peer => true, :ca_file => AUTHORITATIVE_CACERT, :hostname => $name)
      end

      def ssl_verify_peer(cert, preverify_ok)
        $preverify_result = preverify_ok
        EM.stop_event_loop
      end
    end

    def test_against_legitimate
      $name = "www.facebook.com"
      EM.run { EM.connect($name, 443, WebClient) }
      assert $preverify_result
    end

    def test_against_wrong_cn
      $name = "promanagerstaging.parentyreitmeier.com"
      EM.run { EM.connect($name, 443, WebClient) }
      refute $preverify_result
    end

    def test_against_self_signed
      $name = "cryptoanarchy.org"
      EM.run { EM.connect($name, 443, WebClient) }
      refute $preverify_result
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
