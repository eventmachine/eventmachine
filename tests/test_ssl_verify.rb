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

    assert_empty Server.verify_cb_args # no client cert sent
    assert_empty Client.verify_cb_args # VERIFY_NONE: ssl_verify_peer isn't called

    refute Client.handshake_completed? unless "TLSv1.3" == Client.cipher_protocol
    refute Server.handshake_completed?
  end

  def test_server_override_with_accept
    omit_if(rbx?)

    server = { verify_peer: true, ssl_verify_result: true }

    client_server Client, Server, client: CERT_CONFIG, server: server

    # OpenSSL can't verify because its x509_store isn't configured
    # but after we insist the chain certs are okay, it's happy with the peer.
    #
    # n.b. the error strings might change between openssl versions
    assert_equal [
      {ok: false, depth: 0, code: 20, string: "unable to get local issuer certificate"},
      {ok: false, depth: 0, code: 21, string: "unable to verify the first certificate"},
      *(Server.verify_cb_args[2] ? [{ok: true, depth: 0, code: 0, string: "ok"}] : [])
    ], Server.verify_cb_args
    assert_empty Client.verify_cb_args # VERIFY_NONE: ssl_verify_peer not called

    assert_equal CERT_PEM, Server.cert
    assert Client.handshake_completed?
    assert Server.handshake_completed?
  end

  def test_client_override_with_accept
    omit_if(rbx?)

    client = { hostname: "localhost", verify_peer: true, ssl_verify_result: true }

    client_server Client, Server, server: CERT_CONFIG, client: client

    # OpenSSL can't verify because its x509_store isn't configured
    # but after we insist the chain certs are okay, it's happy with the peer.
    #
    # n.b. the error strings might change between openssl versions
    assert_equal [
      {ok: false, depth: 0, code: 20, string: "unable to get local issuer certificate"},
      {ok: false, depth: 0, code: 21, string: "unable to verify the first certificate"},
      *(Client.verify_cb_args[2] ? [{ok: true, depth: 0, code: 0, string: "ok"}] : [])
    ], Client.verify_cb_args
    assert_empty Server.verify_cb_args # no client cert sent

    assert_equal CERT_PEM, Client.cert
    assert Client.handshake_completed?
    assert Server.handshake_completed?
  end

  def test_encoded_server_override_with_accept
    omit_if(rbx?)

    server = { hostname: "localhost", verify_peer: true, ssl_verify_result: true }

    client_server Client, Server, client: ENCODED_CERT_CONFIG, server: server

    # OpenSSL can't verify because its X509_STORE isn't configured
    # but after we insist the chain certs are okay, it's happy with the peer.
    #
    # n.b. the error strings might change between openssl versions
    assert_equal [
      {ok: false, depth: 0, code: 20, string: "unable to get local issuer certificate"},
      {ok: false, depth: 0, code: 21, string: "unable to verify the first certificate"},
      *(Server.verify_cb_args[2] ? [{ok: true, depth: 0, code: 0, string: "ok"}] : [])
    ], Server.verify_cb_args
    assert_empty Client.verify_cb_args # VERIFY_NONE: ssl_verify_peer not called

    assert Client.handshake_completed?
    assert Server.handshake_completed?
    assert_equal CERT_PEM, Server.cert
  end

  def test_encoded_client_override_with_accept
    omit_if(rbx?)

    client = { hostname: "localhost", verify_peer: true, ssl_verify_result: true }

    client_server Client, Server, server: ENCODED_CERT_CONFIG, client: client

    # OpenSSL can't verify because its X509_STORE isn't configured
    # but after we insist the chain certs are okay, it's happy with the peer.
    #
    # n.b. the error strings might change between openssl versions
    assert_equal [
      {ok: false, depth: 0, code: 20, string: "unable to get local issuer certificate"},
      {ok: false, depth: 0, code: 21, string: "unable to verify the first certificate"},
      *(Client.verify_cb_args[2] ? [{ok: true, depth: 0, code: 0, string: "ok"}] : [])
    ], Client.verify_cb_args
    assert_empty Server.verify_cb_args # no client cert sent

    assert Client.handshake_completed?
    assert Server.handshake_completed?
    assert_equal CERT_PEM, Client.cert
  end

  def test_deny_server
    omit_if(rbx?)

    server = { verify_peer: true, ssl_verify_result: false }

    client_server Client, Server, client: CERT_CONFIG, server: server

    # OpenSSL can't verify because its X509_STORE isn't configured
    # but it gives up after the first because we agreed with it.
    #
    # n.b. the error strings might change between openssl versions
    assert_equal [
      {ok: false, depth: 0, code: 20, string: "unable to get local issuer certificate"},
    ], Server.verify_cb_args
    assert_empty Client.verify_cb_args # VERIFY_NONE: ssl_verify_peer not called

    assert_equal CERT_PEM, Server.cert
    refute Client.handshake_completed? unless "TLSv1.3" == Client.cipher_protocol
    refute Server.handshake_completed?
  end

  def test_deny_client
    omit_if(rbx?)

    client = { verify_peer: true, ssl_verify_result: false }

    client_server Client, Server, server: CERT_CONFIG, client: client

    # OpenSSL can't verify because its X509_STORE isn't configured
    # but it gives up after the first because we agreed with it.
    #
    # n.b. the error strings might change between openssl versions
    assert_equal [
      {ok: false, depth: 0, code: 20, string: "unable to get local issuer certificate"},
    ], Client.verify_cb_args
    assert_empty Server.verify_cb_args # no client cert sent

    refute Client.handshake_completed? unless "TLSv1.3" == Client.cipher_protocol
    refute Server.handshake_completed?
    assert_equal CERT_PEM, Client.cert
  end

  def test_backwards_compatible_server
    omit_if(rbx?)

    server = { verify_peer: true, ssl_verify_result: true,
               ssl_old_verify_peer: true }

    client_server Client, Server, client: CERT_CONFIG, server: server

    # Old server handlers can continue in blissful ignorance of OpenSSL's
    # diagnosis, just as they always have....
    assert_equal [
      {ok: :unknown, cert: CERT_PEM},
      {ok: :unknown, cert: CERT_PEM},
      *(Server.verify_cb_args[2] ? [{ok: :unknown, cert: CERT_PEM}] : [])
    ], Server.verify_cb_args
    assert_equal CERT_PEM, Server.cert

    assert Client.handshake_completed?
    assert Server.handshake_completed?
  end

  def test_backwards_compatible_client
    omit_if(rbx?)

    client = { verify_peer: true, ssl_verify_result: true,
               ssl_old_verify_peer: true }

    client_server Client, Server, server: CERT_CONFIG, client: client

    # Old client handlers can continue in blissful ignorance of OpenSSL's
    # diagnosis, just as they always have....
    assert_equal [
      {ok: :unknown, cert: CERT_PEM},
      {ok: :unknown, cert: CERT_PEM},
      *(Client.verify_cb_args[2] ? [{ok: :unknown, cert: CERT_PEM}] : [])
    ], Client.verify_cb_args
    assert_empty Server.verify_cb_args # no client cert sent

    assert_equal CERT_PEM, Client.cert
    assert Client.handshake_completed?
    assert Server.handshake_completed?
  end

end if EM.ssl?
