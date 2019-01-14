require_relative 'em_test_helper'

if EM.ssl?

  class TestSslProtocols < Test::Unit::TestCase

    IP, PORT = "127.0.0.1", 16784
    RUBY_SSL_GE_2_1 = OpenSSL::VERSION >= '2.1'

    module Client
      @@handshake_completed = false

      def self.ssl_vers=(val = nil)
        @@ssl_vers = val
      end

      def self.handshake_completed?
        @@handshake_completed
      end

      def post_init
        @@handshake_completed = false
        if @@ssl_vers
          start_tls(:ssl_version => @@ssl_vers)
        else
          start_tls
        end
      end

      def ssl_handshake_completed
        @@handshake_completed = true
      end
    end

    module Server
      @@handshake_completed = false

      def self.ssl_vers=(val = nil)
        @@ssl_vers = val
      end

      def self.handshake_completed? ; @@handshake_completed end

      def post_init
        @@handshake_completed = false
        if @@ssl_vers
          start_tls(:ssl_version => @@ssl_vers)
        else
          start_tls
        end
      end

      def ssl_handshake_completed
        @@handshake_completed = true
      end
    end

    def client_server(client = nil, server = nil)
      EM.run do
        Client.ssl_vers, Server.ssl_vers = client, server
        EM.start_server IP, PORT, Server
        EM.connect IP, PORT, Client
        EM.add_timer(0.3) { EM.stop_event_loop }
      end
    end

    def test_invalid_ssl_version
      assert_raises(RuntimeError, "Unrecognized SSL/TLS Version: badinput") do
        client_server %w(tlsv1 badinput), %w(tlsv1 badinput)
      end
    end

    def test_any_to_v3
      omit("SSLv3 is (correctly) unavailable") if EM::OPENSSL_NO_SSL3
      client_server SSL_AVAIL, %w(SSLv3)
      assert Client.handshake_completed?
      assert Server.handshake_completed?
    end

    def test_any_to_tlsv1_2
      client_server SSL_AVAIL, %w(TLSv1_2)
      assert Client.handshake_completed?
      assert Server.handshake_completed?
    end

    def test_case_insensitivity
      lower_case = SSL_AVAIL.map { |p| p.downcase }
      client_server %w(tlsv1), lower_case
      assert Client.handshake_completed?
      assert Server.handshake_completed?
    end

    def test_v3_to_any
      omit("SSLv3 is (correctly) unavailable") if EM::OPENSSL_NO_SSL3
      client_server %w(SSLv3), SSL_AVAIL
      assert Client.handshake_completed?
      assert Server.handshake_completed?
    end

    def test_tlsv1_2_to_any
      client_server %w(TLSv1_2), SSL_AVAIL
      assert Client.handshake_completed?
      assert Server.handshake_completed?
    end

    def test_v3_to_v3
      omit("SSLv3 is (correctly) unavailable") if EM::OPENSSL_NO_SSL3
      client_server %w(SSLv3), %w(SSLv3)
      assert Client.handshake_completed?
      assert Server.handshake_completed?
    end

    def test_tlsv1_2_to_tlsv1_2
      client_server %w(TLSv1_2), %w(TLSv1_2)
      assert Client.handshake_completed?
      assert Server.handshake_completed?
    end

    def test_tlsv1_3_to_tlsv1_3
      omit("TLSv1_3 is unavailable") unless EM.const_defined? :EM_PROTO_TLSv1_3
      client_server %w(TLSv1_3), %w(TLSv1_3)
      assert Client.handshake_completed?
      assert Server.handshake_completed?
    end

    def test_any_to_any
      client_server SSL_AVAIL, SSL_AVAIL
      assert Client.handshake_completed?
      assert Server.handshake_completed?
    end

    def test_default_to_default
      client_server
      assert Client.handshake_completed?
      assert Server.handshake_completed?
    end

    module ServerStopAfterHandshake
      def self.ssl_vers=(val)
        @@ssl_vers = val
      end

      def self.handshake_completed? ; @@handshake_completed end

      def post_init
        @@handshake_completed = false
        start_tls(:ssl_version => @@ssl_vers)
      end

      def ssl_handshake_completed
        @@handshake_completed = true
        EM.stop_event_loop
      end
    end

    def external_client(ext_min, ext_max, ext_ssl, server)
      EM.run do
        setup_timeout(2)
        ServerStopAfterHandshake.ssl_vers = server
        EM.start_server(IP, PORT, ServerStopAfterHandshake)
        EM.defer do
          sock = TCPSocket.new(IP, PORT)
          ctx = OpenSSL::SSL::SSLContext.new
          if RUBY_SSL_GE_2_1
            ctx.min_version = ext_min if ext_min
            ctx.max_version = ext_max if ext_max
          else
            ctx.ssl_version = ext_ssl
          end
          ssl = OpenSSL::SSL::SSLSocket.new(sock, ctx)
          ssl.connect
          ssl.close rescue nil
          sock.close rescue nil
        end
      end
      assert ServerStopAfterHandshake.handshake_completed?
    end

    def test_v3_with_external_client
      omit("SSLv3 is (correctly) unavailable") if EM::OPENSSL_NO_SSL3
      external_client nil, nil, :SSLv3_client, %w(SSLv3)
    end

    # Fixed Server
    def test_tlsv1_2_with_external_client
      external_client nil, nil, :SSLv23_client, %w(TLSv1_2)
    end

    def test_tlsv1_3_with_external_client
      omit("TLSv1_3 is unavailable") unless EM.const_defined? :EM_PROTO_TLSv1_3
      external_client nil, nil, :SSLv23_client, %w(TLSv1_3)
    end

    # Fixed Client
    def test_any_with_external_client_tlsv1_2
      external_client :TLS1_2, :TLS1_2, :TLSv1_2_client, SSL_AVAIL
    end

    def test_any_with_external_client_tlsv1_3
      omit("TLSv1_3 is unavailable") unless EM.const_defined? :EM_PROTO_TLSv1_3
      external_client :TLS1_3, :TLS1_3, :TLSv1_2_client, SSL_AVAIL
    end

    # Refuse a client?
    def test_tlsv1_2_required_with_external_client
      EM.run do
        n = 0
        EM.add_periodic_timer(0.5) do
          n += 1
          (EM.stop rescue nil) if n == 2
        end
        ServerStopAfterHandshake.ssl_vers = %w(TLSv1_2)
        EM.start_server(IP, PORT, ServerStopAfterHandshake)
        EM.defer do
          sock = TCPSocket.new(IP, PORT)
          ctx = OpenSSL::SSL::SSLContext.new
          if RUBY_SSL_GE_2_1
            ctx.max_version = :TLS1_1
          else
            ctx.ssl_version = :TLSv1_client
          end
          ssl = OpenSSL::SSL::SSLSocket.new(sock, ctx)
          assert_raise(OpenSSL::SSL::SSLError) { ssl.connect }
          ssl.close rescue nil
          sock.close rescue nil
          EM.stop rescue nil
        end
      end
      assert !ServerStopAfterHandshake.handshake_completed?
    end
  end
else
  warn "EM built without SSL support, skipping tests in #{__FILE__}"
end