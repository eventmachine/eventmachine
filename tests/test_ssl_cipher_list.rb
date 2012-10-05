require 'em_test_helper'

class TestSSLCipherList < Test::Unit::TestCase

  module ServerHandler

    def post_init
      start_tls({:cipher_list => $server_cipher_list})
    end

    def ssl_handshake_completed
      $server_called_back = true
    end

  end

  module ClientHandler

    def post_init
      start_tls({:cipher_list => $client_cipher_list})
    end

    def ssl_handshake_completed
      $client_called_back = true
      EM.stop_event_loop
    end

  end

  def test_ssl_compatible_cipher_list
    $server_called_back, $client_called_back = false, false

    $server_cipher_list = "ALL"
    $client_cipher_list = "DES-CBC3-SHA"

    EM.run {
      EM.start_server("127.0.0.1", 9999, ServerHandler)
      EM.connect("127.0.0.1", 9999, ClientHandler)
      EM.add_timer(0.5) { EM.stop }
    }

    assert($server_called_back, "server ssl handshake NOT completed in 0.5 seconds")
    assert($client_called_back, "client ssl handshake NOT completed in 0.5 seconds")
  end

  def test_ssl_non_compatible_cipher_list
    $server_called_back, $client_called_back = false, false

    $server_cipher_list = ""  # Use EM default cipher which does not include "DES-CBC3-SHA"
    $client_cipher_list = "DES-CBC3-SHA"

    EM.run {
      EM.start_server("127.0.0.1", 19999, ServerHandler)
      EM.connect("127.0.0.1", 19999, ClientHandler)
      EM.add_timer(0.5) { EM.stop }
    }

    assert_equal(false, $server_called_back)
    assert_equal(false, $client_called_back)
  end

end if EM.ssl?
