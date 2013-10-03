require 'em_test_helper'

class TestSSLMethods < Test::Unit::TestCase
  def setup
      $dir = File.dirname(File.expand_path(__FILE__)) + '/'
      $client_cert_from_file = File.read($dir+'client.crt')
      $server_cert_from_file = File.read($dir+'server.crt')
  end

  module ServerHandler

    def post_init
      start_tls(:private_key_file => $dir+'server.key', :cert_chain_file => $dir+'server.crt', :verify_peer => true)
    end

    def ssl_handshake_completed
      $server_called_back = true
      $client_cert_value = get_peer_cert
    end

    def ssl_verify_peer cert
      true
    end
  end

  module ClientHandler

    def post_init
      start_tls(:private_key_file => $dir+'client.key', :cert_chain_file => $dir+'client.crt')
    end

    def ssl_handshake_completed
      $client_called_back = true
      $server_cert_value = get_peer_cert
      EM.stop_event_loop
    end

  end

  def test_ssl_methods
    $server_called_back, $client_called_back = false, false
    $server_cert_value, $client_cert_value = nil, nil

    EM.run {
      EM.start_server("127.0.0.1", 9999, ServerHandler)
      EM.connect("127.0.0.1", 9999, ClientHandler)
    }

    assert($server_called_back)
    assert($client_called_back)

    assert_equal($server_cert_from_file, $server_cert_value.gsub("\r", ""))
    assert_equal($client_cert_from_file, $client_cert_value.gsub("\r", ""))
  end

end if EM.ssl?
