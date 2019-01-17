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
