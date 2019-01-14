require_relative 'em_test_helper'

class TestSslEcdhCurve < Test::Unit::TestCase

  if EM.ssl?
    SSL_LIB_VERS = EM::OPENSSL_LIBRARY_VERSION[/OpenSSL (\d+\.\d+\.\d+)/, 1]
      .split('.').map(&:to_i)
  end

  module Client
    def post_init
      start_tls
    end

    def ssl_handshake_completed
      $client_handshake_completed = true
      $client_cipher_name = get_cipher_name
      close_connection unless /TLSv1\.3/i =~ get_cipher_protocol
    end

    def unbind
      EM.stop_event_loop
    end
  end

  module Server
    def post_init
      if (SSL_LIB_VERS <=> [1, 1]) == 1
        start_tls(:cipher_list => "ECDH", :ssl_version => %w(TLSv1_2))
      else
        start_tls(:ecdh_curve => "prime256v1", :cipher_list => "ECDH", :ssl_version => %w(TLSv1_2))
      end
    end

    def ssl_handshake_completed
      $server_handshake_completed = true
      $server_cipher_name = get_cipher_name
    end
  end

  module Server1_3
    def post_init
      start_tls(:cipher_list => "ECDH", :ssl_version => %w(TLSv1_3))
    end

    def ssl_handshake_completed
      $server_handshake_completed = true
      $server_cipher_name = get_cipher_name
      close_connection if /TLSv1\.3/i =~ get_cipher_protocol
    end
  end

  module NoCurveServer
    def post_init
      start_tls(:cipher_list => "ECDH", :ssl_version => %w(TLSv1_2))
    end

    def ssl_handshake_completed
      $server_handshake_completed = true
      $server_cipher_name = get_cipher_name
    end
  end

  def test_no_ecdh_curve
    omit("No SSL") unless EM.ssl?
    omit_if(rbx?)
    omit("OpenSSL 1.1.x (and later) auto selects curve") if (SSL_LIB_VERS <=> [1, 1]) == 1

    $client_handshake_completed, $server_handshake_completed = false, false

    EM.run {
      EM.start_server("127.0.0.1", 16784, NoCurveServer)
      EM.connect("127.0.0.1", 16784, Client)
    }

    assert(!$client_handshake_completed)
    assert(!$server_handshake_completed)
  end

  def test_ecdh_curve
    omit("No SSL") unless EM.ssl?
    omit_if(EM.library_type == :pure_ruby && RUBY_VERSION < "2.3.0")
    omit_if(rbx?)

    $client_handshake_completed, $server_handshake_completed = false, false
    $server_cipher_name, $client_cipher_name = nil, nil

    EM.run {
      EM.start_server("127.0.0.1", 16784, Server)
      EM.connect("127.0.0.1", 16784, Client)
    }

    assert($client_handshake_completed)
    assert($server_handshake_completed)

    assert($client_cipher_name.length > 0)
    assert_equal($client_cipher_name, $server_cipher_name)

    assert_match(/^(AECDH|ECDHE)/, $client_cipher_name)
  end

  def test_ecdh_curve_tlsv1_3
    omit("No SSL") unless EM.ssl?
    omit_if(EM.library_type == :pure_ruby && RUBY_VERSION < "2.3.0")
    omit_if(rbx?)
    omit("TLSv1_3 is unavailable") unless EM.const_defined? :EM_PROTO_TLSv1_3

    $client_handshake_completed, $server_handshake_completed = false, false
    $server_cipher_name, $client_cipher_name = nil, nil

    EM.run {
      EM.start_server("127.0.0.1", 16784, Server1_3)
      EM.connect("127.0.0.1", 16784, Client)
    }

    assert($client_handshake_completed)
    assert($server_handshake_completed)

    assert($client_cipher_name.length > 0)
    assert_equal($client_cipher_name, $server_cipher_name)
    # see https://wiki.openssl.org/index.php/TLS1.3#Ciphersuites
    # may depend on OpenSSL build options
    assert_equal("TLS_AES_256_GCM_SHA384", $client_cipher_name)
  end
end
