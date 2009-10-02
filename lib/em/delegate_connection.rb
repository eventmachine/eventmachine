require 'socket'

module EventMachine
  # A simple delegate provider that will pass on all callbacks the connection
  # receives to the given delegate object, prepended with a reference to
  # itself.
  #
  # Example Usage:
  #
  # The following is an example of a central logging delegate. Only one
  # instance of this delegate needs to exist, as such users may more easily
  # aggregate less stated connection events.
  #
  #   my_delegate = Class.new do
  #     def method_missing(name, connection, *args)
  #       puts [
  #         Time.now, connection.signature, connection.ip_port, name, *args
  #       ].inspect
  #     end
  #   end
  #   EM.connect(host, port, DelegateConnection, my_delegate)
  #
  # A Note on the Init Callback:
  #
  # Delegates must respond to the callback methods or an error will be
  # raised at runtime. One additional callback has been added from initialize,
  # in order to not clobber the API from normal ruby class construction, when
  # a new connection is initialized #init will be called on the delegate.
  class DelegateConnection < Connection

    # The given delegate will be used, init will be called each time a new
    # connection is opened, passing in the connection object.
    def initialize(delegate)
      @delegate = delegate
      @delegate.init(self)
    end

    # Retreive the connections ip and port from the reactor.
    def address_tuple
      @port, @ip = Socket.unpack_sockaddr_in(get_peername)
    end

    # The remote IP.
    def ip
      @ip || address_tuple && @ip
    end

    # The remote Port.
    def port
      @port || address_tuple && @port
    end

    # A consistent, frozen string containing ip:port, well suited for a hash
    # key.
    def ip_port
      @ip_port ||= "#{@ip}:#{@port}".freeze
    end

    def post_init
      # TODO pass in connection details
      @delegate.post_init(self)
    end

    def receive_data(data)
      @delegate.receive_data(self, data)
    end

    def ssl_handshake_completed
      @delegate.ssl_handshake_completed(self)
    end

    def ssl_verify_peer(cert)
      @delegate.ssl_verify_peer(self, cert)
    end

    def unbind
      @delegate.unbind(self)
    end

    def proxy_target_unbound
      @delegate.proxy_target_unbound(self)
    end

    def connection_completed
      @delegate.connection_completed(self)
    end
  end
end