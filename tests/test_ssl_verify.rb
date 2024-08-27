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

  # TODO: move this text fixture sanity check to another file...
  def test_encoded_private_key_matches_pass
    # just a sanity check...
    assert_nothing_thrown {
      pass = ENCODED_CERT_CONFIG[:private_key_pass]
      key  = File.read(ENCODED_CERT_CONFIG[:private_key_file])
      key  = OpenSSL::PKey.read(key, pass)
    }
  end

  # TODO: pass depth, error number, and error string to verify callback

  # TODO: make and use one or more intermediate CAs
  # TODO: use eventmachine.localhost and/or eventmachine.test
  # TODO: it seems to work but... breaks many of the other tests.
  def test_openssl_accept_with_ca_file_and_hostname
    omit "why does ca_file change global state for all SSL_CTX?"
    chain = CERT_PEM + CA_PEM
    server = {
      cert: chain, private_key_file: PRIVATE_KEY_FILE,
      verify_peer: true, ssl_verify_result: :ossl,
    }
    client = { ca_file: CA_FILE, hostname: "localhost", verify_peer: true, ssl_verify_result: :ossl }
    client_server Client, Server, server: server, client: client
    assert_empty Server.preverify_ok # no client cert sent
    assert_equal [
      true,  # =>
      true,  # =>
    ], Client.preverify_ok
    assert Client.handshake_completed? unless "TLSv1.3" == Client.cipher_protocol
    assert Server.handshake_completed?
  end

  # TODO: make and use an intermediate CA
  # TODO: use eventmachine.localhost and/or eventmachine.test
  # TODO: configure a chain file properly?
  def test_openssl_fail_unverified_chain
    omit_if(rbx?)
    chain = CERT_PEM + CA_PEM
    server = {
      cert: chain, private_key_file: PRIVATE_KEY_FILE,
      verify_peer: true, ssl_verify_result: :ossl,
    }
    client = { verify_peer: true, ssl_verify_result: :ossl }
    client_server Client, Server, server: server, client: client
    assert_empty Server.preverify_ok # no client cert sent
    assert_equal [
      false,  # => depth=0:num=20:unable to get local issuer certificate
    ], Client.preverify_ok
    refute Client.handshake_completed? unless "TLSv1.3" == Client.cipher_protocol
    refute Server.handshake_completed?
  end

  def test_openssl_fail_unknown_ca
    omit_if(rbx?)
    server = CERT_CONFIG.merge verify_peer: true, ssl_verify_result: :ossl
    client = { verify_peer: true, ssl_verify_result: :ossl }
    client_server Client, Server, server: server, client: client
    assert_empty Server.preverify_ok # no client cert sent
    assert_equal [
      false,  # => depth=0:num=20:unable to get local issuer certificate
    ], Client.preverify_ok
    refute Client.handshake_completed? unless "TLSv1.3" == Client.cipher_protocol
    refute Server.handshake_completed?
  end

  def test_fail_no_peer_cert
    omit_if(rbx?)

    server = { verify_peer: true, fail_if_no_peer_cert: true,
      ssl_verify_result: "|RAISE|Verify peer should not get called for a client without a certificate" }

    client_server Client, Server, server: server

    assert_empty Server.preverify_ok # no client cert sent
    assert_empty Client.preverify_ok # VERIFY_NONE: ssl_verify_peer isn't called

    refute Client.handshake_completed? unless "TLSv1.3" == Client.cipher_protocol
    refute Server.handshake_completed?
  end

  def test_server_override_with_accept
    omit_if(EM.library_type == :pure_ruby) # Server has a default cert chain
    omit_if(rbx?)

    server = { verify_peer: true, ssl_verify_result: true }

    client_server Client, Server, client: CERT_CONFIG, server: server

    # OpenSSL can't verify because it doesn't trust our CA.  But we insist its
    # errors don't matter, so it eventually agrees with us.
    assert_equal [
      false,  # => depth=0:num=20:unable to get local issuer certificate
      false,  # => depth=0:num=21:unable to verify the first certificate
      true    # => depth-0:num=0:ok
    ], Server.preverify_ok
    assert_empty Client.preverify_ok # VERIFY_NONE: ssl_verify_peer not called

    assert_equal CERT_PEM, Server.cert
    assert Client.handshake_completed?
    assert Server.handshake_completed?
  end

  def test_client_override_with_accept
    omit_if(EM.library_type == :pure_ruby) # Server has a default cert chain
    omit_if(rbx?)

    client = { hostname: "localhost", verify_peer: true, ssl_verify_result: true }

    client_server Client, Server, server: CERT_CONFIG, client: client

    # OpenSSL can't verify because it doesn't trust our CA.  But we insist its
    # errors don't matter, so it eventually agrees with us.
    assert_equal [
      false,  # => depth=0:num=20:unable to get local issuer certificate
      false,  # => depth=0:num=21:unable to verify the first certificate
      true    # => depth-0:num=0:ok
    ], Client.preverify_ok
    assert_empty Server.preverify_ok # no client cert sent

    assert_equal CERT_PEM, Client.cert
    assert Client.handshake_completed?
    assert Server.handshake_completed?
  end

  def test_encoded_server_override_with_accept
    omit_if(EM.library_type == :pure_ruby) # Server has a default cert chain
    omit_if(rbx?)

    server = { hostname: "localhost", verify_peer: true, ssl_verify_result: true }

    client_server Client, Server, client: ENCODED_CERT_CONFIG, server: server

    assert_equal [false, false, true], Server.preverify_ok
    assert_empty Client.preverify_ok # VERIFY_NONE: ssl_verify_peer not called

    assert Client.handshake_completed?
    assert Server.handshake_completed?
    assert_equal CERT_PEM, Server.cert
  end

  def test_encoded_client_override_with_accept
    omit_if(EM.library_type == :pure_ruby) # Server has a default cert chain
    omit_if(rbx?)

    client = { hostname: "localhost", verify_peer: true, ssl_verify_result: true }

    client_server Client, Server, server: ENCODED_CERT_CONFIG, client: client

    assert_equal [false, false, true], Client.preverify_ok
    assert_empty Server.preverify_ok # no client cert sent

    assert Client.handshake_completed?
    assert Server.handshake_completed?
    assert_equal CERT_PEM, Client.cert
  end

  def test_deny_server
    omit_if(EM.library_type == :pure_ruby) # Server has a default cert chain
    omit_if(rbx?)

    server = { verify_peer: true, ssl_verify_result: false }

    client_server Client, Server, client: CERT_CONFIG, server: server

    assert_equal [false], Server.preverify_ok
    assert_empty Client.preverify_ok # VERIFY_NONE: ssl_verify_peer not called

    assert_equal CERT_PEM, Server.cert
    refute Client.handshake_completed? unless "TLSv1.3" == Client.cipher_protocol
    refute Server.handshake_completed?
  end

  def test_deny_client
    omit_if(EM.library_type == :pure_ruby) # Server has a default cert chain
    omit_if(rbx?)

    client = { verify_peer: true, ssl_verify_result: false }

    client_server Client, Server, server: CERT_CONFIG, client: client

    assert_equal [false], Client.preverify_ok
    assert_empty Server.preverify_ok # no client cert sent

    refute Client.handshake_completed? unless "TLSv1.3" == Client.cipher_protocol
    refute Server.handshake_completed?
    assert_equal CERT_PEM, Client.cert
  end

  def test_backwards_compatible_server
    omit_if(EM.library_type == :pure_ruby) # server has a default cert chain
    omit_if(rbx?)

    server = { verify_peer: true, ssl_verify_result: true,
               ssl_old_verify_peer: true }

    client_server Client, Server, client: CERT_CONFIG, server: server

    # Old server handlers can continue in blissful ignorance of OpenSSL's
    # diagnosis, just as they always have....
    assert_equal [:a_complete_mystery] * 3, Server.preverify_ok
    assert_equal CERT_PEM,            Server.cert

    assert Client.handshake_completed?
    assert Server.handshake_completed?
  end

  def test_backwards_compatible_client
    omit_if(EM.library_type == :pure_ruby) # server has a default cert chain
    omit_if(rbx?)

    client = { verify_peer: true, ssl_verify_result: true,
               ssl_old_verify_peer: true }

    client_server Client, Server, server: CERT_CONFIG, client: client

    # Old client handlers can continue in blissful ignorance of OpenSSL's
    # diagnosis, just as they always have....
    assert_equal [:a_complete_mystery] * 3, Client.preverify_ok
    assert_empty Server.preverify_ok # no client cert sent

    assert_equal CERT_PEM, Client.cert
    assert Client.handshake_completed?
    assert Server.handshake_completed?
  end

end if EM.ssl?
