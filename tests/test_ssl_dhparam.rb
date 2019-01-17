# frozen_string_literal: true

require_relative 'em_test_helper'

class TestSSLDhParam < Test::Unit::TestCase

  require_relative 'em_ssl_handlers'
  include EMSSLHandlers

  DH_PARAM_FILE = File.join(__dir__, 'dhparam.pem')

  DH_1_2 =   { cipher_list: "DHE,EDH", ssl_version: %w(TLSv1_2) }
  CLIENT_1_2 = { client_unbind: true,  ssl_version: %w(TLSv1_2) }

  def test_no_dhparam
    omit_if(EM.library_type == :pure_ruby) # DH will work with defaults
    omit_if(rbx?)

    client_server client: CLIENT_1_2, server: DH_1_2

    refute Client.handshake_completed?
    refute Server.handshake_completed?
  end

  def test_dhparam_1_2
    omit_if(rbx?)

    client_server client: CLIENT_1_2, server: DH_1_2.merge(dhparam: DH_PARAM_FILE)

    assert Client.handshake_completed?
    assert Server.handshake_completed?

    assert Client.cipher_name.length > 0
    assert_equal Client.cipher_name, Server.cipher_name

    assert_match(/^(DHE|EDH)/, Client.cipher_name)
  end

  def test_dhparam_1_3
    omit_if(rbx?)
    omit("TLSv1_3 is unavailable") unless EM.const_defined? :EM_PROTO_TLSv1_3

    client = { client_unbind: true, ssl_version: %w(TLSv1_3) }
    server = { dhparam: DH_PARAM_FILE, cipher_list: "DHE,EDH", ssl_version: %w(TLSv1_3) }
    client_server client: client, server: server

    assert Client.handshake_completed?
    assert Server.handshake_completed?

    assert Client.cipher_name.length > 0
    assert_equal Client.cipher_name, Server.cipher_name

    # see https://wiki.openssl.org/index.php/TLS1.3#Ciphersuites
    # may depend on OpenSSL build options
    assert_equal "TLS_AES_256_GCM_SHA384", Client.cipher_name
  end
end if EM.ssl?
