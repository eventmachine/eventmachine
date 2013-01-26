require "test/unit"
require 'tempfile'

require 'em_test_helper'

module EM
  def self._set_mocks
    class <<self
      alias set_tls_parms_old set_tls_parms
      alias start_tls_old start_tls
      begin
        old, $VERBOSE = $VERBOSE, nil
        def set_tls_parms *args; end
        def start_tls *args; end
      ensure
        $VERBOSE = old
      end
    end
  end

  def self._clear_mocks
    class <<self
      begin
        old, $VERBOSE = $VERBOSE, nil
        alias set_tls_parms set_tls_parms_old
        alias start_tls start_tls_old
      ensure
        $VERBOSE = old
      end
    end
  end
end

  

class TestSslArgs < Test::Unit::TestCase
  def setup
    EM._set_mocks
  end
  
  def teardown
    EM._clear_mocks
  end

  OPTIONS = [
    :private_key_file,
    :cert_chain_file
  ]
  
  def test_tls_params_file_doesnt_exist
    parameters = OPTIONS.map do |opt|
      [ opt, "foo_#{opt}" ]
    end

    parameters.all? do |opt, f|
      assert(!File.exists?(f), "Cert file #{f} seems to exist, and should not for the tests")
    end
    
    # associate_callback_target is a pain! (build!)
    conn = EM::Connection.new('foo')

    # test all the combinations of parameters
    (1 .. parameters.length).each do |n|
      parameters.combination(n) do |params|
        assert_raises(EM::FileNotFoundException) do
          conn.start_tls(Hash[ *params.flatten ])
        end
      end
    end
  end
  
  def test_tls_params_file_does_exist
    tempfiles = []
    parameters = OPTIONS.map do |opt|
      tempfiles << Tempfile.new('em_test')
      [ opt, tempfiles.last.path ]
    end
    conn = EM::Connection.new('foo')
    begin
      conn.start_tls Hash[ *parameters.flatten ]
    rescue Object
      assert(false, 'should not have raised an exception')
    end
  ensure
    tempfiles.each do |tf|
      tf.close
      tf.unlink
    end
  end
end if EM.ssl?
