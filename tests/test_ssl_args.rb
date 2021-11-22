# frozen_string_literal: true

require_relative 'em_test_helper'
require 'tempfile'

class TestSSLArgs < Test::Unit::TestCase

  require_relative 'em_ssl_handlers'
  include EMSSLHandlers

  def test_tls_params_file_doesnt_exist
    priv_file, cert_file = 'foo_priv_key', 'bar_cert_file'
    [priv_file, cert_file].all? do |f|
      assert(!File.exist?(f), "Cert file #{f} seems to exist, and should not for the tests")
    end

    assert_raises EM::FileNotFoundException do
      client_server client: { private_key_file: priv_file }
    end

    assert_raises EM::FileNotFoundException do
      client_server client: { cert_chain_file: cert_file }
    end

    assert_raises EM::FileNotFoundException do
      client_server client: { private_key_file: priv_file, cert_chain_file: cert_file }
    end
  end

  def test_tls_cert_not_defined_twice
    assert_raises EM::BadCertParams do
      client_server client: { cert: CERT_PEM, cert_chain_file: CERT_FILE }
    end
  end

  def test_tls_key_not_defined_twice
    assert_raises EM::BadPrivateKeyParams do
      client_server client: { private_key_file: PRIVATE_KEY_FILE,
                              private_key: PRIVATE_KEY_PEM,
                              cert_chain_file: CERT_FILE }
    end
  end

  def test_tls_key_requires_cert
    #specifying a key but no cert will generate an error at SSL level
    #with a misleading text
    #140579476657920:error:1417A0C1:SSL routines:tls_post_process_client_hello:no shared cipher

    assert_raises EM::BadParams do
      client_server client: { private_key_file: PRIVATE_KEY_FILE }
    end
  end

  def _test_tls_params_file_improper
    priv_file_path = Tempfile.new('em_test').path
    cert_file_path = Tempfile.new('em_test').path
    params = { private_key_file: priv_file_path,
                cert_chain_file: cert_file_path }
    begin
      client_server client: params
    rescue Object
      assert false, 'should not have raised an exception'
    end
  end
end if EM.ssl?
