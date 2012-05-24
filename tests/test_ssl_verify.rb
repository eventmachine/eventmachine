require 'em_test_helper'

if EM.ssl?
  class TestSslVerify < Test::Unit::TestCase
    CERT_DIRECTORY = File.expand_path("../certs", __FILE__) + '/'

    module Server
      def post_init
        start_tls(
          :private_key_file => CERT_DIRECTORY + "#$cert.key",
          :cert_chain_file  => CERT_DIRECTORY + "#$cert.crt",
          :private_key_pwd  => 'asdf'
        )
      end

      def ssl_handshake_completed
        $server_handshake_completed = true
      end
    end

    module Client
      def post_init
        start_tls(:verify_peer => true, :ca_file => CERT_DIRECTORY + 'cacert.pem', :hostname => $name)
      end

      def ssl_verify_peer(cert, preverify_ok)
        $cert_from_server = cert
        $preverify_result = preverify_ok
        if $stub_verify != nil
          ret = $stub_verify
          $stub_verify = nil
          return ret
        end
        preverify_ok
      end

      def ssl_handshake_completed
        $client_handshake_completed = true
        close_connection
      end

      def unbind
        EM.stop_event_loop
      end
    end

    def test_valid_certificates_pass_preverification
      $name = "127.0.0.1"
      $cert = "ca-signed-127.0.0.1"
      EM.run {
        EM.start_server($name, 16784, Server)
        EM.connect($name, 16784, Client)
      }
      assert $preverify_result
    end

    def test_certificates_with_incorrect_common_names_fail_preverification
      $name = "127.0.0.1"
      $cert = "ca-signed-eventmachine"
      EM.run {
        EM.start_server($name, 16784, Server)
        EM.connect($name, 16784, Client)
      }
      refute $preverify_result
    end

    def test_self_signed_certificates_fail_preverification
      $name = "EventMachine"
      $cert = "self-signed-eventmachine"
      EM.run {
        EM.start_server("127.0.0.1", 16784, Server)
        EM.connect("127.0.0.1", 16784, Client)
      }
      refute $preverify_result
    end

    def test_accepting_connection
      $client_handshake_completed, $server_handshake_completed = false, false
      $stub_verify = true
      $name = "127.0.0.1"
      $cert = "ca-signed-127.0.0.1"
      EM.run {
        EM.start_server("127.0.0.1", 16784, Server)
        EM.connect("127.0.0.1", 16784, Client)
      }

      cert = File.read(CERT_DIRECTORY + 'ca-signed-127.0.0.1.crt')
      assert_equal(cert, $cert_from_server)
      assert($client_handshake_completed)
      assert($server_handshake_completed)
    end

    def test_rejecting_connection
      $client_handshake_completed, $server_handshake_completed = false, false
      $stub_verify = false
      $name = "127.0.0.1"
      $cert = "ca-signed-127.0.0.1"
      EM.run {
        EM.start_server("127.0.0.1", 16784, Server)
        EM.connect("127.0.0.1", 16784, Client)
      }

      assert(!$client_handshake_completed)
      assert(!$server_handshake_completed)
    end
  end
else
  warn "EM built without SSL support, skipping tests in #{__FILE__}"
end
