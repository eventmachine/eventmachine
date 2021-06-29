# frozen_string_literal: true

require_relative 'em_test_helper'

class TestSSLInlineCert < Test::Unit::TestCase

  require_relative 'em_ssl_handlers'
  include EMSSLHandlers

  CERT_FILE="#{__dir__}/client.crt"
  PRIVATE_KEY_FILE="#{__dir__}/client.key"
  ENCODED_KEY_FILE="#{__dir__}/encoded_client.key"
  
  CERT = File.read CERT_FILE
  PRIVATE_KEY = File.read PRIVATE_KEY_FILE
  ENCODED_KEY = File.read ENCODED_KEY_FILE

  ENCODED_KEY_PASS = 'nicercat'
  
  def test_proper_key_required_for_client
    # an assert in ssl.ccp code make this fail
    # with no way of catching the error
    omit_if(rbx?)

    bad_key=PRIVATE_KEY.dup
    assert(bad_key[100]!=4)
    bad_key[100]='4'

    server = { verify_peer: true, ssl_verify_result: true }

    assert_raises EM::InvalidPrivateKey do
      client_server Client, Server,
                    client: { private_key: bad_key,
                              cert: CERT },
                    server: server
    end
    refute Client.handshake_completed?
  end

  def test_proper_key_required_for_server
    # an assert in ssl.ccp code make this fail
    # with no way of catching the error
    omit_if(rbx?)

    bad_key=PRIVATE_KEY.dup
    assert(bad_key[100]!=4)
    bad_key[100]='4'

    server = { verify_peer: true, ssl_verify_result: true,
               private_key: bad_key, cert: CERT }

    assert_raises EM::InvalidPrivateKey do
      client_server Client, Server,
                    server: server
    end
    refute Server.handshake_completed?
  end

  def test_accept_client_key_inline_cert_inline
    omit_if(rbx?)

    server = { verify_peer: true, ssl_verify_result: true }
    client = { private_key: PRIVATE_KEY,
               cert: CERT }

    client_server Client, Server,
                  client: client,
                  server: server

    assert Client.handshake_completed?
    assert Server.handshake_completed?
    assert_equal CERT, Server.cert
  end

  def test_accept_server_key_inline_cert_inline
    omit_if(rbx?)

    client = { verify_peer: true, ssl_verify_result: true }
    server = { private_key: PRIVATE_KEY,
               cert: CERT }

    client_server Client, Server,
                  client: client,
                  server: server

    assert Client.handshake_completed?
    assert Server.handshake_completed?
    assert_equal CERT, Client.cert
  end

  def test_accept_client_encoded_key_inline_cert_inlince
    omit_if(rbx?)

    server = { verify_peer: true, ssl_verify_result: true }
    client = { private_key: ENCODED_KEY,
               private_key_pass: ENCODED_KEY_PASS,
               cert: CERT }

    client_server Client, Server,
                  client: client,
                  server: server

    assert Client.handshake_completed?
    assert Server.handshake_completed?
    assert_equal CERT, Server.cert
  end

  def test_accept_server_encoded_key_inline_cert_inlince
    omit_if(rbx?)

    client = { verify_peer: true, ssl_verify_result: true }
    server = { private_key: ENCODED_KEY,
               private_key_pass: ENCODED_KEY_PASS,
               cert: CERT }

    client_server Client, Server,
                  client: client,
                  server: server

    assert Client.handshake_completed?
    assert Server.handshake_completed?
    assert_equal CERT, Client.cert
  end

  def test_accept_client_key_from_file_cert_inline
    omit_if(rbx?)

    server = { verify_peer: true, ssl_verify_result: true }
    client = { private_key_file: PRIVATE_KEY_FILE,
               cert: CERT }

    client_server Client, Server,
                  client: client,
                  server: server

    assert Client.handshake_completed?
    assert Server.handshake_completed?
    assert_equal CERT, Server.cert
  end

  def test_accept_server_key_from_file_cert_inline
    omit_if(rbx?)

    client = { verify_peer: true, ssl_verify_result: true }
    server = { private_key_file: PRIVATE_KEY_FILE,
               cert: CERT }

    client_server Client, Server,
                  client: client,
                  server: server

    assert Client.handshake_completed?
    assert Server.handshake_completed?
    assert_equal CERT, Client.cert
  end

  def test_accept_client_key_inline_cert_from_file
    omit_if(rbx?)

    server = { verify_peer: true, ssl_verify_result: true }
    client = { private_key: PRIVATE_KEY,
               cert_chain_file: CERT_FILE }

    client_server Client, Server,
                  client: client,
                  server: server

    assert Client.handshake_completed?
    assert Server.handshake_completed?
    assert_equal CERT, Server.cert
  end

  def test_accept_server_key_inline_cert_from_file
    omit_if(rbx?)

    client = { verify_peer: true, ssl_verify_result: true }
    server = { private_key: PRIVATE_KEY,
               cert_chain_file: CERT_FILE }

    client_server Client, Server,
                  client: client,
                  server: server

    assert Client.handshake_completed?
    assert Server.handshake_completed?
    assert_equal CERT, Client.cert
  end

  def test_accept_client_encoded_key_inline_cert_from_file
    omit_if(rbx?)

    server = { verify_peer: true, ssl_verify_result: true }
    client = { private_key: ENCODED_KEY,
               private_key_pass: ENCODED_KEY_PASS,
               cert_chain_file: CERT_FILE }

    client_server Client, Server,
                  client: client,
                  server: server

    assert Client.handshake_completed?
    assert Server.handshake_completed?
    assert_equal CERT, Server.cert
  end

  def test_accept_server_encoded_key_inline_cert_from_file
    omit_if(rbx?)

    client = { verify_peer: true, ssl_verify_result: true}
    server = { private_key: ENCODED_KEY,
               private_key_pass: ENCODED_KEY_PASS,
               cert_chain_file: CERT_FILE }

    client_server Client, Server,
                  client: client,
                  server: server

    assert Client.handshake_completed?
    assert Server.handshake_completed?
    assert_equal CERT, Client.cert
  end
end if EM.ssl?
