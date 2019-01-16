# frozen_string_literal: true

require_relative 'em_test_helper'

class TestSSLMethods < Test::Unit::TestCase

  require_relative 'em_ssl_handlers'
  include EMSSLHandlers

  def test_ssl_methods
    omit_if(rbx?)

    client_server
    
    assert Server.handshake_completed?
    assert Client.handshake_completed?

    assert Server.cert_value.is_a? NilClass
    assert Client.cert_value.is_a? String

    assert Client.cipher_bits > 0
    assert_equal Client.cipher_bits, Server.cipher_bits

    assert Client.cipher_name.length > 0
    assert_match(/AES/, Client.cipher_name)
    assert_equal Client.cipher_name, Server.cipher_name

    assert Client.cipher_protocol.start_with? "TLS"
    assert_equal Client.cipher_protocol, Server.cipher_protocol
  end
end  if EM.ssl?
