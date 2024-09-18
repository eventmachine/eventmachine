module EventMachine

  module SSL

    module X509

      # This class wraps some of the data available from an X509_STORE_CTX
      # object.
      #
      # @see Connection#ssl_verify_peer
      class StoreContext

        def initialize(current_cert, error_depth, error, error_string)
          require "openssl"
          @current_cert = OpenSSL::X509::Certificate.new(current_cert)
          @error = error
          @error_depth = error_depth
          @error_string = error_string
          freeze
        end

        # @return [OpenSSL::X509::Certificate] the certificate in this context
        attr_reader :current_cert

        # @return [Integer] the error code of this context.
        #
        # See "ERROR CODES" in the X509_STORE_CTX_GET_ERROR(3SSL) man page for a
        # full description of all error codes.
        #
        # @note The "error" is also used for non-errors, i.e. X509_V_OK.
        attr_reader :error

        # @return [Integer] the depth of the error
        #
        # This is a nonnegative integer representing where in the certificate
        # chain the error occurred. If it is zero it occurred in the end entity
        # certificate, one if it is the certificate which signed the end entity
        # certificate and so on.
        #
        # @note The "error" depth is also used for non-errors, i.e. X509_V_OK.
        attr_reader :error_depth

        # @return [String] human readable error string for verification {error}
        #
        # @note The "error" string can be "ok", i.e. no error.
        attr_reader :error_string

      end

    end
  end
end
