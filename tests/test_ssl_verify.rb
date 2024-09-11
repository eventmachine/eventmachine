# frozen_string_literal: true

require_relative 'em_test_helper'

class TestSSLVerify < Test::Unit::TestCase

  require_relative 'em_ssl_handlers'
  include EMSSLHandlers

  CERT_CONFIG = {
    # ca_file:          "#{CERTS_DIR}/eventmachine-ca.crt",
    private_key_file: PRIVATE_KEY_FILE,
    cert_chain_file:  "#{CERTS_DIR}/em-localhost.crt",
  }

  ENCODED_CERT_CONFIG = {
    # ca_file:          "#{CERTS_DIR}/eventmachine-ca.crt",
    private_key_pass: ENCODED_KEY_PASS,
    private_key_file: ENCODED_KEY_FILE,
    cert_chain_file:  "#{CERTS_DIR}/em-localhost.crt",
  }



  def test_fail_no_peer_cert
    omit_if(rbx?)

    server = { verify_peer: true, fail_if_no_peer_cert: true,
      ssl_verify_result: "|RAISE|Verify peer should not get called for a client without a certificate" }

    client_server Client, Server, server: server

    refute Client.handshake_completed? unless "TLSv1.3" == Client.cipher_protocol
    refute Server.handshake_completed?
  end

  def test_accept_server
    omit_if(rbx?)

    server = { verify_peer: true, ssl_verify_result: true }

    client_server Client, Server, client: CERT_CONFIG, server: server

    assert_equal CERT_PEM, Server.cert
    assert Client.handshake_completed?
    assert Server.handshake_completed?
  end

  def test_accept_client
    omit_if(rbx?)

    client = { verify_peer: true, ssl_verify_result: true }

    client_server Client, Server, server: CERT_CONFIG, client: client

    assert_equal CERT_PEM, Client.cert
    assert Client.handshake_completed?
    assert Server.handshake_completed?
  end

  def test_encoded_accept_server
    omit_if(rbx?)

    server = { verify_peer: true, ssl_verify_result: true }

    client_server Client, Server, client: ENCODED_CERT_CONFIG, server: server

    assert Client.handshake_completed?
    assert Server.handshake_completed?
    assert_equal CERT_PEM, Server.cert
  end

  def test_encoded_accept_client
    omit_if(rbx?)

    client = { verify_peer: true, ssl_verify_result: true }

    client_server Client, Server, server: ENCODED_CERT_CONFIG, client: client

    assert Client.handshake_completed?
    assert Server.handshake_completed?
    assert_equal CERT_PEM, Client.cert
  end

  def test_deny_server
    omit_if(rbx?)

    server = { verify_peer: true, ssl_verify_result: false }

    client_server Client, Server, client: CERT_CONFIG, server: server

    assert_equal CERT_PEM, Server.cert
    refute Client.handshake_completed? unless "TLSv1.3" == Client.cipher_protocol
    refute Server.handshake_completed?
  end

  def test_deny_client
    omit_if(rbx?)

    client = { verify_peer: true, ssl_verify_result: false }

    client_server Client, Server, server: CERT_CONFIG, client: client

    refute Client.handshake_completed? unless "TLSv1.3" == Client.cipher_protocol
    refute Server.handshake_completed?
    assert_equal CERT_PEM, Client.cert
  end
end if EM.ssl?
