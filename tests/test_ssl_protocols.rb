# frozen_string_literal: true

require_relative 'em_test_helper'

# For OpenSSL 1.1.0 and later, cipher_protocol returns single cipher, older
# versions return "TLSv1/SSLv3"
# TLSv1.1 handshake_completed Server/Client callback order is reversed from
# older protocols

class TestSSLProtocols < Test::Unit::TestCase

  require_relative 'em_ssl_handlers'
  include EMSSLHandlers

  # We're checking for whether Context min_version= & max_version= are defined, but
  # JRuby has a bug where they're defined, but the private method they call isn't
  RUBY_SSL_GE_2_1 = OpenSSL::SSL::SSLContext.private_instance_methods(false).include?(:set_minmax_proto_version)

  def test_invalid_ssl_version
    assert_raises(RuntimeError, "Unrecognized SSL/TLS Version: badinput") do
      client = { ssl_version: %w(tlsv1 badinput) }
      server = { ssl_version: %w(tlsv1 badinput) }
      client_server client: client, server: server
    end
  end

  def test_any_to_v3
    omit("SSLv3 is (correctly) unavailable") if EM::OPENSSL_NO_SSL3
    client_server client: TLS_ALL, server: SSL_3
    assert Client.handshake_completed?
    assert Server.handshake_completed?
  end

  def test_any_to_tlsv1_2
    client_server client: TLS_ALL, server: TLS_1_2
    assert Client.handshake_completed?
    assert Server.handshake_completed?
    if IS_SSL_GE_1_1
      assert_equal "TLSv1.2", Client.cipher_protocol
    end
  end

  def test_case_insensitivity
    lower_case = SSL_AVAIL.map { |p| p.downcase }
    client = { ssl_version: %w(tlsv1_2) }
    server = { ssl_version: lower_case  }
    client_server client: client, server: server
    assert Client.handshake_completed?
    assert Server.handshake_completed?
  end

  def test_v3_to_any
    omit("SSLv3 is (correctly) unavailable") if EM::OPENSSL_NO_SSL3
    client_server client: SSL_3, server: TLS_ALL
    assert Client.handshake_completed?
    assert Server.handshake_completed?
  end

  def test_tlsv1_2_to_any
    client_server client: TLS_1_2, server: TLS_ALL
    assert Client.handshake_completed?
    assert Server.handshake_completed?
    if IS_SSL_GE_1_1
      assert_equal "TLSv1.2", Server.cipher_protocol
    end
  end

  def test_v3_to_v3
    omit("SSLv3 is (correctly) unavailable") if EM::OPENSSL_NO_SSL3
    client_server client: SSL_3, server: SSL_3
    assert Client.handshake_completed?
    assert Server.handshake_completed?
  end

  def test_tlsv1_2_to_tlsv1_2
    client_server client: TLS_1_2, server: TLS_1_2
    assert Client.handshake_completed?
    assert Server.handshake_completed?
    if IS_SSL_GE_1_1
      assert_equal "TLSv1.2", Client.cipher_protocol
      assert_equal "TLSv1.2", Server.cipher_protocol
    end
  end

  def test_tlsv1_3_to_tlsv1_3
    omit("TLSv1_3 is unavailable") unless EM.const_defined? :EM_PROTO_TLSv1_3
    client_server client: TLS_1_3, server: TLS_1_3
    assert Client.handshake_completed?
    assert Server.handshake_completed?
    assert_equal "TLSv1.3", Client.cipher_protocol
    assert_equal "TLSv1.3", Server.cipher_protocol
  end

  def test_any_to_any
    client_server client: TLS_ALL, server: TLS_ALL
    assert Client.handshake_completed?
    assert Server.handshake_completed?
    if IS_SSL_GE_1_1
      best_protocol = SSL_AVAIL.last.tr "_", "."
      assert_equal best_protocol, Client.cipher_protocol
      assert_equal best_protocol, Server.cipher_protocol
    end
  end

  def test_default_to_default
    client_server
    assert Client.handshake_completed?
    assert Server.handshake_completed?
    if IS_SSL_GE_1_1
      best_protocol = SSL_AVAIL.last.tr "_", "."
      assert_equal best_protocol, Client.cipher_protocol
      assert_equal best_protocol, Server.cipher_protocol
    end
  end

  def external_client(ext_min, ext_max, ext_ssl, server)
    EM.run do
#        setup_timeout 2
      EM.start_server IP, PORT, Server, server.merge( { stop_after_handshake: true} )
      EM.defer do
        sock = TCPSocket.new IP, PORT
        ctx = OpenSSL::SSL::SSLContext.new
        if RUBY_SSL_GE_2_1
          ctx.min_version = ext_min if ext_min
          ctx.max_version = ext_max if ext_max
        else
          ctx.ssl_version = ext_ssl
        end
        ssl = OpenSSL::SSL::SSLSocket.new(sock, ctx)
        ssl.connect
        ssl.close rescue nil
        sock.close rescue nil
      end
    end
    assert Server.handshake_completed?
  end

  def test_v3_with_external_client
    omit("SSLv3 is (correctly) unavailable") if EM::OPENSSL_NO_SSL3
    external_client nil, nil, :SSLv3_client, SSL_3
  end

  # Fixed Server
  def test_tlsv1_2_with_external_client
    external_client nil, nil, :SSLv23_client, TLS_1_2
  end

  def test_tlsv1_3_with_external_client
    omit("TLSv1_3 is unavailable") unless EM.const_defined?(:EM_PROTO_TLSv1_3) &&
      OpenSSL::SSL.const_defined?(:TLS1_3_VERSION)
    external_client nil, nil, :SSLv23_client, TLS_1_3
  end

  # Fixed Client
  def test_any_with_external_client_tlsv1_2
    external_client :TLS1_2, :TLS1_2, :TLSv1_2_client, TLS_ALL
  end

  def test_any_with_external_client_tlsv1_3
    omit("TLSv1_3 is unavailable") unless EM.const_defined? :EM_PROTO_TLSv1_3
    external_client :TLS1_3, :TLS1_3, :TLSv1_2_client, TLS_ALL
  end

  # Refuse a client?
  def test_tlsv1_2_required_with_external_client
    EM.run do
      n = 0
      EM.add_periodic_timer(0.5) do
        n += 1
        (EM.stop rescue nil) if n == 2
      end
      EM.start_server IP, PORT, Server, TLS_1_2.merge( { stop_after_handshake: true} )
      EM.defer do
        sock = TCPSocket.new IP, PORT
        ctx = OpenSSL::SSL::SSLContext.new
        if RUBY_SSL_GE_2_1
          ctx.max_version = :TLS1_1
        else
          ctx.ssl_version = :TLSv1_client
        end
        ssl = OpenSSL::SSL::SSLSocket.new sock, ctx
        assert_raise(OpenSSL::SSL::SSLError) { ssl.connect }
        ssl.close  rescue nil
        sock.close rescue nil
        EM.stop    rescue nil
      end
    end
    refute Server.handshake_completed?
  end
end if EM.ssl?
