require_relative 'em_test_helper'

if EM.ssl?
  class TestSslExtensions < Test::Unit::TestCase

    IP, PORT = "127.0.0.1", 16784
  
    module Client
      def self.ssl_vers=(val = nil)
        @@ssl_vers = val
      end

      def post_init
        start_tls(:sni_hostname => 'example.com', :ssl_version => @@ssl_vers)
      end
    end

    module Server
      @@handshake_completed = false
      @@sni_hostname = 'Not set'
      
      def self.handshake_completed? ; !!@@handshake_completed end
      def self.sni_hostname         ;   @@sni_hostname        end

      def post_init
        start_tls
      end

      def ssl_handshake_completed
        @@handshake_completed = true
        @@sni_hostname = get_sni_hostname
      end
    end

    def client_server(client = nil)
      EM.run do
        Client.ssl_vers = client
        EM.start_server IP, PORT, Server
        EM.connect IP, PORT, Client
        EM.add_timer(0.3) { EM.stop_event_loop }
      end
    end
    
    def test_tlsext_sni_hostname_1_2
      client_server %w(TLSv1_2)
      assert Server.handshake_completed?
      assert_equal 'example.com', Server.sni_hostname
    end
    
    def test_tlsext_sni_hostname_1_3
      omit("TLSv1_3 is unavailable") unless SSL_AVAIL.include? "tlsv1_3"
      client_server %w(TLSv1_3)
      assert Server.handshake_completed?
      assert_equal 'example.com', Server.sni_hostname
    end
    
  end
else
  warn "EM built without SSL support, skipping tests in #{__FILE__}"
end
