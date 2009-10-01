module EventMachine
  class DelegateConnection < Connection
    def initialize(delegate)
      @delegate = delegate
      @delegate.init(self)
    end

    def address_tuple
      @port, @ip = Socket.unpack_sockaddr_in(get_peername)
    end

    def ip
      @ip || address_tuple && @ip
    end

    def port
      @port || address_tuple && @port
    end

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

  class Server
    def initialize(host, port, delegate = nil, &blk)
      @host, @port = host, port

      set_delegate(delegate || blk)
    end

    def listen
      EM.schedule { @signature = EM.start_server(@host, @port, *@delegate) }
      self
    end

    def stop
      EM.schedule { EM.stop_server(@signature) if @signature }
      self
    end

    def run
      EM.run
    end

    private
    def set_delegate(delegate)
      @delegate = case delegate
      when Class
        [delegate]
      when Module
        [Class.new(EM::Connection) { include delegate }]
      when Proc
        [Module.new &delegate]
        # when nil # TODO
        #   LoggerConnection
      else
        [DelegateConnection, delegate]
      end
    end

  end
end