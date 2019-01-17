# frozen_string_literal: true

require_relative 'em_test_helper'

class TestSSLExtensions < Test::Unit::TestCase

  require_relative 'em_ssl_handlers'
  include EMSSLHandlers

  def test_tlsext_sni_hostname_1_2
    client = { sni_hostname: 'example.com', ssl_version: %w(TLSv1_2) }
    client_server client: client
    assert Server.handshake_completed?
    assert_equal 'example.com', Server.sni_hostname
  end
  
  def test_tlsext_sni_hostname_1_3
    omit("TLSv1_3 is unavailable") unless EM.const_defined? :EM_PROTO_TLSv1_3
    client = { sni_hostname: 'example.com', ssl_version: %w(TLSv1_3) }
    client_server client: client
    assert Server.handshake_completed?
    assert_equal 'example.com', Server.sni_hostname
  end
end if EM.ssl?
