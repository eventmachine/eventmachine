# frozen_string_literal: true

require_relative 'em_test_helper'

class TestSSLEcdhCurve < Test::Unit::TestCase

  require_relative 'em_ssl_handlers'
  include EMSSLHandlers

  def test_no_ecdh_curve
    omit_if(rbx?)
    omit("OpenSSL 1.1.x (and later) auto selects curve") if IS_SSL_GE_1_1

    client_server server: { cipher_list: "ECDH", ssl_version: %w(TLSv1_2) }

    refute Client.handshake_completed?
    refute Server.handshake_completed?
  end

  def test_ecdh_curve_tlsv1_2
    omit_if(EM.library_type == :pure_ruby && RUBY_VERSION < "2.3.0")
    omit_if(rbx?)

    server = { cipher_list: "ECDH", ssl_version: %w(TLSv1_2) }
    server.merge!(ecdh_curve: "prime256v1") unless IS_SSL_GE_1_1

    client_server server: server

    assert Client.handshake_completed?
    assert Server.handshake_completed?

    assert Client.cipher_name.length > 0
    assert_equal Client.cipher_name, Server.cipher_name

    assert_match(/^(AECDH|ECDHE)/, Client.cipher_name)
  end

  def test_ecdh_curve_tlsv1_3
    omit_if(EM.library_type == :pure_ruby && RUBY_VERSION < "2.3.0")
    omit_if(rbx?)
    omit("TLSv1_3 is unavailable") unless EM.const_defined? :EM_PROTO_TLSv1_3

    tls = { cipher_list: "ECDH", ssl_version: %w(TLSv1_3) }

    client_server server: tls

    assert Client.handshake_completed?
    assert Server.handshake_completed?

    assert Client.cipher_name.length > 0
    assert_equal Client.cipher_name, Server.cipher_name

    # see https://wiki.openssl.org/index.php/TLS1.3#Ciphersuites
    # may depend on OpenSSL build options
    assert_equal "TLS_AES_256_GCM_SHA384", Client.cipher_name
  end
end if EM.ssl?
