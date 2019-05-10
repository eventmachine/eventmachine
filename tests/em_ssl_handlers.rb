# frozen_string_literal: true

##
# EMSSLHandlers has two classes, `Client` and `Server`, and one method,
# `client_server`, which is a wrapper around
#
#    EM.run do
#      EM.start_server IP, PORT, s_hndlr, server
#      EM.connect IP, PORT, c_hndlr, client
#    end  
#
# It also passes parameters to the `start_tls` call within the `post_init`
# callbacks of Client and Server.
#
# Client and Server have most standard callbacks and many 'get_*' function values
# as attributes.
#
# `Client` has a `:client_unbind` parameter, which when set to true, calls
# `EM.stop_event_loop` in the `unbind` callback.
# 
# `Server` has two additional parameters.
#
# `:ssl_verify_result`, which is normally set to true/false for the
# `ssl_verify_peer` return value.  If it is set to a String starting with "|RAISE|",
# the remaing string will be raised.
# 
# `:stop_after_handshake`, when set to true, will close the connection and then
# call `EM.stop_event_loop`.
#
module EMSSLHandlers

  IP, PORT = "127.0.0.1", 16784

  # is OpenSSL version >= 1.1.0
  IS_SSL_GE_1_1 = (EM::OPENSSL_LIBRARY_VERSION[/OpenSSL (\d+\.\d+\.\d+)/, 1]
    .split('.').map(&:to_i) <=> [1,1]) == 1

  # common start_tls parameters
  SSL_3   = { ssl_version: %w(SSLv3)   }
  TLS_1_2 = { ssl_version: %w(TLSv1_2) }
  TLS_1_3 = { ssl_version: %w(TLSv1_3) }
  TLS_ALL = { ssl_version: Test::Unit::TestCase::SSL_AVAIL }

  module Client
    def initialize(tls = nil)
      @@tls = tls ? tls.dup : tls
      @@handshake_completed = false
      @@cert            = nil
      @@cert_value      = nil
      @@cipher_bits     = nil
      @@cipher_name     = nil
      @@cipher_protocol = nil
      @@ssl_verify_result = @@tls ? @@tls.delete(:ssl_verify_result) : nil
      @@client_unbind = @@tls ? @@tls.delete(:client_unbind) : nil
    end

    def self.cert                 ;   @@cert                end
    def self.cert_value           ;   @@cert_value          end
    def self.cipher_bits          ;   @@cipher_bits         end
    def self.cipher_name          ;   @@cipher_name         end
    def self.cipher_protocol      ;   @@cipher_protocol     end
    def self.handshake_completed? ; !!@@handshake_completed end

    def post_init
      if @@tls
        start_tls @@tls
      else
        start_tls
      end
    end

    def ssl_verify_peer(cert)
      @@cert = cert
      if @@ssl_verify_result.is_a?(String) && @@ssl_verify_result.start_with?("|RAISE|")
        raise @@ssl_verify_result.sub('|RAISE|', '')
      else
        @@ssl_verify_result
      end
    end

    def ssl_handshake_completed
      @@handshake_completed = true
      @@cert_value      = get_peer_cert
      @@cipher_bits     = get_cipher_bits
      @@cipher_name     = get_cipher_name
      @@cipher_protocol = get_cipher_protocol

      if "TLSv1.3" != @@cipher_protocol
        close_connection
        EM.stop_event_loop
      end
    end

    def unbind
      EM.stop_event_loop if @@client_unbind
    end
  end

  module Server
    def initialize(tls = nil)
      @@tls = tls ? tls.dup : tls
      @@handshake_completed = false
      @@cert_value      = nil
      @@cipher_bits     = nil
      @@cipher_name     = nil
      @@cipher_protocol = nil
      @@sni_hostname = "not set"
      @@ssl_verify_result    = @@tls ? @@tls.delete(:ssl_verify_result)    : nil
      @@stop_after_handshake = @@tls ? @@tls.delete(:stop_after_handshake) : nil
    end

    def self.cert                 ;   @@cert                end
    def self.cert_value           ;   @@cert_value          end
    def self.cipher_bits          ;   @@cipher_bits         end
    def self.cipher_name          ;   @@cipher_name         end
    def self.cipher_protocol      ;   @@cipher_protocol     end
    def self.handshake_completed? ; !!@@handshake_completed end
    def self.sni_hostname         ;   @@sni_hostname        end

    def post_init
      if @@tls
        start_tls @@tls
      else
        start_tls
      end
    end

    def ssl_verify_peer(cert)
      @@cert = cert
      if @@ssl_verify_result.is_a?(String) && @@ssl_verify_result.start_with?("|RAISE|")
        raise @@ssl_verify_result.sub('|RAISE|', '')
      else
        @@ssl_verify_result
      end
    end
    
    def ssl_handshake_completed
      @@handshake_completed = true
      @@cert_value      = get_peer_cert
      @@cipher_bits     = get_cipher_bits
      @@cipher_name     = get_cipher_name
      @@cipher_protocol = get_cipher_protocol

      @@sni_hostname    = get_sni_hostname
      if ("TLSv1.3" == @@cipher_protocol) || @@stop_after_handshake
        close_connection
        EM.stop_event_loop
      end
    end

    def unbind
      EM.stop_event_loop unless @@handshake_completed
    end
  end

  def client_server(c_hndlr = Client, s_hndlr = Server,
    client: nil, server: nil, timeout: 3.0)
    EM.run do
      # fail safe stop
      setup_timeout timeout
      EM.start_server IP, PORT, s_hndlr, server
      EM.connect IP, PORT, c_hndlr, client
    end
  end
end if EM.ssl?
