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
# `:ssl_old_verify_peer` when set to true will setup `ssl_verify_peer` to only
# accept one argument, to test for compatibility with the original API.
#
module EMSSLHandlers

  CERTS_DIR        = "#{__dir__}/fixtures"

  CA_NAME          = "eventmachine-ca"
  CERT_NAME        = "em-localhost"

  CA_FILE          = "#{CERTS_DIR}/#{CA_NAME}.crt"
  CERT_FILE        = "#{CERTS_DIR}/#{CERT_NAME}.crt"
  ENCODED_KEY_FILE = "#{CERTS_DIR}/#{CERT_NAME}.aes-key"
  PRIVATE_KEY_FILE = "#{CERTS_DIR}/#{CERT_NAME}.key"
  ENCODED_PASSFILE = "#{CERTS_DIR}/#{CERT_NAME}.pass"
  CA_PEM           = File.read(CA_FILE).freeze
  CERT_PEM         = File.read(CERT_FILE).freeze
  PRIVATE_KEY_PEM  = File.read(PRIVATE_KEY_FILE).freeze
  ENCODED_KEY_PEM  = File.read(ENCODED_KEY_FILE).freeze
  ENCODED_KEY_PASS = File.read(ENCODED_PASSFILE).freeze

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
      @@preverify_ok    = []
      @@cert_value      = nil
      @@cipher_bits     = nil
      @@cipher_name     = nil
      @@cipher_protocol = nil
      @@ssl_verify_result = @@tls ? @@tls.delete(:ssl_verify_result) : nil
      @@client_unbind = @@tls ? @@tls.delete(:client_unbind) : nil
      extend BackCompatVerifyPeer if @@tls&.delete(:ssl_old_verify_peer)
    end

    def self.cert                 ;   @@cert                end
    def self.cert_value           ;   @@cert_value          end
    def self.cipher_bits          ;   @@cipher_bits         end
    def self.cipher_name          ;   @@cipher_name         end
    def self.cipher_protocol      ;   @@cipher_protocol     end
    def self.handshake_completed? ; !!@@handshake_completed end
    def self.preverify_ok         ;   @@preverify_ok        end

    # TODO: replace "verify_peer: false" with ca_file: CA_FILE
    def post_init
      if @@tls
        start_tls verify_peer: false, **@@tls
      else
        start_tls verify_peer: false
      end
    end

    def ssl_verify_peer(cert, preverify_ok)
      # $stderr.puts "    Client, ssl_verify_peer(%p, %p)" % [OpenSSL::X509::Certificate.new(cert).subject.to_s, preverify_ok]
      @@preverify_ok << preverify_ok
      @@cert = cert
      if @@ssl_verify_result.is_a?(String) && @@ssl_verify_result.start_with?("|RAISE|")
        raise @@ssl_verify_result.sub('|RAISE|', '')
      elsif @@ssl_verify_result == :ossl
        preverify_ok
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
      @@cert            = nil
      @@preverify_ok    = []
      @@cert_value      = nil
      @@cipher_bits     = nil
      @@cipher_name     = nil
      @@cipher_protocol = nil
      @@sni_hostname = "not set"
      @@ssl_verify_result    = @@tls ? @@tls.delete(:ssl_verify_result)    : nil
      @@stop_after_handshake = @@tls ? @@tls.delete(:stop_after_handshake) : nil
      extend BackCompatVerifyPeer if @@tls&.delete(:ssl_old_verify_peer)
    end

    def self.cert                 ;   @@cert                end
    def self.cert_value           ;   @@cert_value          end
    def self.cipher_bits          ;   @@cipher_bits         end
    def self.cipher_name          ;   @@cipher_name         end
    def self.cipher_protocol      ;   @@cipher_protocol     end
    def self.handshake_completed? ; !!@@handshake_completed end
    def self.sni_hostname         ;   @@sni_hostname        end
    def self.preverify_ok         ;   @@preverify_ok        end

    def post_init
      if @@tls
        start_tls verify_peer: false, **@@tls
      else
        start_tls verify_peer: false
      end
    end

    def ssl_verify_peer(cert, preverify_ok)
      # $stderr.puts "    Server, ssl_verify_peer(%p, %p)" % [OpenSSL::X509::Certificate.new(cert).subject.to_s, preverify_ok]
      @@preverify_ok << preverify_ok
      @@cert = cert
      if @@ssl_verify_result.is_a?(String) && @@ssl_verify_result.start_with?("|RAISE|")
        raise @@ssl_verify_result.sub('|RAISE|', '')
      elsif @@ssl_verify_result == :ossl
        preverify_ok
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

  module BackCompatVerifyPeer
    def ssl_verify_peer(cert)
      super(cert, :a_complete_mystery)
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
