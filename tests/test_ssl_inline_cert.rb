# frozen_string_literal: true

require_relative 'em_test_helper'

class TestSSLInlineCert < Test::Unit::TestCase

  require_relative 'em_ssl_handlers'
  include EMSSLHandlers

  # changing two bytes, just in case one is a newline.
  # using rot13.5.1, aka rot32 (13*2 + 5 + 1).
  BAD_KEY = PRIVATE_KEY_PEM.dup.tap {|bad_key|
    bad_key[100,2] = bad_key[100,2]
      .tr("A-Za-z0-9/+", "N-ZA-Mn-za-m5-90-4+/")
  }.freeze

  def test_proper_key_required_for_client
    # an assert in ssl.ccp code make this fail
    # with no way of catching the error
    omit_if(rbx?)

    server = { verify_peer: true, ssl_verify_result: true }

    assert_raises EM::InvalidPrivateKey do
      client_server Client, Server,
                    client: { private_key: BAD_KEY,
                              cert: CERT_PEM },
                    server: server
    end
    refute Client.handshake_completed?
  end

  def test_proper_key_required_for_server
    # an assert in ssl.ccp code make this fail
    # with no way of catching the error
    omit_if(rbx?)

    server = { verify_peer: true, ssl_verify_result: true,
               private_key: BAD_KEY, cert: CERT_PEM }

    assert_raises EM::InvalidPrivateKey do
      client_server Client, Server,
                    server: server
    end
    refute Server.handshake_completed?
  end

  def test_accept_client_key_inline_cert_inline
    omit_if(rbx?)

    server = { verify_peer: true, ssl_verify_result: true }
    client = { private_key: PRIVATE_KEY_PEM,
               cert: CERT_PEM }

    client_server Client, Server,
                  client: client,
                  server: server

    assert Client.handshake_completed?
    assert Server.handshake_completed?
    assert_equal CERT_PEM, Server.cert
  end

  def test_accept_server_key_inline_cert_inline
    omit_if(rbx?)

    client = { verify_peer: true, ssl_verify_result: true }
    server = { private_key: PRIVATE_KEY_PEM,
               cert: CERT_PEM }

    client_server Client, Server,
                  client: client,
                  server: server

    assert Client.handshake_completed?
    assert Server.handshake_completed?
    assert_equal CERT_PEM, Client.cert
  end

  def test_accept_client_encoded_key_inline_cert_inlince
    omit_if(rbx?)

    server = { verify_peer: true, ssl_verify_result: true }
    client = { private_key: ENCODED_KEY_PEM,
               private_key_pass: ENCODED_KEY_PASS,
               cert: CERT_PEM }

    client_server Client, Server,
                  client: client,
                  server: server

    assert Client.handshake_completed?
    assert Server.handshake_completed?
    assert_equal CERT_PEM, Server.cert
  end

  def test_accept_server_encoded_key_inline_cert_inlince
    omit_if(rbx?)

    client = { verify_peer: true, ssl_verify_result: true }
    server = { private_key: ENCODED_KEY_PEM,
               private_key_pass: ENCODED_KEY_PASS,
               cert: CERT_PEM }

    client_server Client, Server,
                  client: client,
                  server: server

    assert Client.handshake_completed?
    assert Server.handshake_completed?
    assert_equal CERT_PEM, Client.cert
  end

  def test_accept_client_key_from_file_cert_inline
    omit_if(rbx?)

    server = { verify_peer: true, ssl_verify_result: true }
    client = { private_key_file: PRIVATE_KEY_FILE,
               cert: CERT_PEM }

    client_server Client, Server,
                  client: client,
                  server: server

    assert Client.handshake_completed?
    assert Server.handshake_completed?
    assert_equal CERT_PEM, Server.cert
  end

  def test_accept_server_key_from_file_cert_inline
    omit_if(rbx?)

    client = { verify_peer: true, ssl_verify_result: true }
    server = { private_key_file: PRIVATE_KEY_FILE,
               cert: CERT_PEM }

    client_server Client, Server,
                  client: client,
                  server: server

    assert Client.handshake_completed?
    assert Server.handshake_completed?
    assert_equal CERT_PEM, Client.cert
  end

  def test_accept_client_key_inline_cert_from_file
    omit_if(rbx?)

    server = { verify_peer: true, ssl_verify_result: true }
    client = { private_key: PRIVATE_KEY_PEM,
               cert_chain_file: CERT_FILE }

    client_server Client, Server,
                  client: client,
                  server: server

    assert Client.handshake_completed?
    assert Server.handshake_completed?
    assert_equal CERT_PEM, Server.cert
  end

  def test_accept_server_key_inline_cert_from_file
    omit_if(rbx?)

    client = { verify_peer: true, ssl_verify_result: true }
    server = { private_key: PRIVATE_KEY_PEM,
               cert_chain_file: CERT_FILE }

    client_server Client, Server,
                  client: client,
                  server: server

    assert Client.handshake_completed?
    assert Server.handshake_completed?
    assert_equal CERT_PEM, Client.cert
  end

  def test_accept_client_encoded_key_inline_cert_from_file
    omit_if(rbx?)

    server = { verify_peer: true, ssl_verify_result: true }
    client = { private_key: ENCODED_KEY_PEM,
               private_key_pass: ENCODED_KEY_PASS,
               cert_chain_file: CERT_FILE }

    client_server Client, Server,
                  client: client,
                  server: server

    assert Client.handshake_completed?
    assert Server.handshake_completed?
    assert_equal CERT_PEM, Server.cert
  end

  def test_accept_server_encoded_key_inline_cert_from_file
    omit_if(rbx?)

    client = { verify_peer: true, ssl_verify_result: true}
    server = { private_key: ENCODED_KEY_PEM,
               private_key_pass: ENCODED_KEY_PASS,
               cert_chain_file: CERT_FILE }

    client_server Client, Server,
                  client: client,
                  server: server

    assert Client.handshake_completed?
    assert Server.handshake_completed?
    assert_equal CERT_PEM, Client.cert
  end
end if EM.ssl?
