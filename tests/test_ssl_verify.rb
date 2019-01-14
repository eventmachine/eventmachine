require_relative 'em_test_helper'

class TestSslVerify < Test::Unit::TestCase

  DIR = File.dirname(File.expand_path(__FILE__)) + '/'
  CERT_FROM_FILE = File.read(DIR+'client.crt')

  IP, PORT = "127.0.0.1", 16784

  module ClientNoCert
    @@handshake_completed = nil
    def self.handshake_completed? ; !!@@handshake_completed end

    def post_init
      @@handshake_completed = false
      start_tls()
    end

    def ssl_handshake_completed
      @@handshake_completed = true
    end

    def unbind
      @@handshake_completed = false
    end
  end

  module Client
    @@handshake_completed = nil
    def self.handshake_completed? ; !!@@handshake_completed end
    def self.timer=(val)          ;   @@timer = val         end

    def post_init #G connection_completed
      @client_closed = false
      @@handshake_completed = nil
      @@timer = false
      start_tls(:private_key_file => DIR+'client.key', :cert_chain_file => DIR+'client.crt')
    end

    def ssl_handshake_completed
      @@handshake_completed = true
    end

    def unbind
      @@handshake_completed = false unless @@timer
    end
  end

  module AcceptServer
    @@handshake_completed = nil
    def self.handshake_completed? ; !!@@handshake_completed end
    def self.cert ; @@cert end

    def post_init
      @@cert = nil
      @@handshake_completed = false
      start_tls(:verify_peer => true)
    end

    def ssl_verify_peer(cert)
      @@cert = cert
      true
    end

    def ssl_handshake_completed
      @@handshake_completed = true
    end
  end

  module DenyServer
    @@handshake_completed = nil
    def self.handshake_completed? ; !!@@handshake_completed end
    def self.cert ; @@cert end

    def post_init
      @@cert = nil
      @@handshake_completed = nil
      start_tls(:verify_peer => true)
    end

    def ssl_verify_peer(cert)
      @@cert = cert
      # Do not accept the peer. This should now cause the connection to shut down without the SSL handshake being completed.
      false
    end

    def ssl_handshake_completed
      @@handshake_completed = true
    end
  end

  module FailServerNoPeerCert
    @@handshake_completed = nil
    def self.handshake_completed? ; !!@@handshake_completed end

    def post_init
      @@handshake_completed = false
      start_tls(:verify_peer => true, :fail_if_no_peer_cert => true)
    end

    def ssl_verify_peer(cert)
      raise "Verify peer should not get called for a client without a certificate"
    end

    def ssl_handshake_completed
      @@handshake_completed = true
    end
  end

  def em_run(server, client)
    EM.run {
      EM.start_server IP, PORT, server
      EM.connect IP, PORT, client
      EM.add_timer(0.3) {
        Client.timer = true
        EM.stop_event_loop
      }
    }
  end

  def test_fail_no_peer_cert
    omit("No SSL") unless EM.ssl?
    omit_if(rbx?)

    em_run FailServerNoPeerCert, ClientNoCert

    assert !ClientNoCert.handshake_completed?
    assert !FailServerNoPeerCert.handshake_completed?
  end

  def test_accept_server
    omit("No SSL") unless EM.ssl?
    omit_if(EM.library_type == :pure_ruby) # Server has a default cert chain
    omit_if(rbx?)

    em_run AcceptServer, Client

    assert_equal CERT_FROM_FILE, AcceptServer.cert
    assert Client.handshake_completed?
    assert AcceptServer.handshake_completed?
  end

  def test_deny_server
    omit("No SSL") unless EM.ssl?
    omit_if(EM.library_type == :pure_ruby) # Server has a default cert chain
    omit_if(rbx?)

    em_run DenyServer, Client

    assert_equal CERT_FROM_FILE, DenyServer.cert
    assert !Client.handshake_completed?
    assert !DenyServer.handshake_completed?
  end
end
