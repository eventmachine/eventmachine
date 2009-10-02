module EventMachine
  # An object oriented approach at EventMachine servers. This server class
  # provides a convenient handle to EventMachine server bindings. The delegate
  # parameter defines the connection module, or class that will be used to
  # process connections. Optionally, users may pass a block which will be used
  # as if it were passed to Module.new and passed in. The delegate paramenter
  # will also accept an already constructed object to which it will delegate
  # the callbacks for all connections to that object using
  # EventMachine::DelegateConnection.
  class Server

    # The host and port parameters define the listen side of a server binding.
    # The delegate parameter defines the object, module, or class that will be
    # utilised. Users may also pass a block instead of a delegate object which
    # will define a module for the connections.
    def initialize(host, port, delegate = nil, *delegate_args, &blk)
      @host, @port = host, port
      set_delegate(delegate || blk)
      @delegate_args = delegate_args
    end

    # Schedule the start of the server listener. If the reactor is not yet
    # running, then this method will simply schedule listening for the reactor
    # start.
    def listen
      args = @delegate + @delegate_args
      EM.schedule { @signature = EM.start_server(@host, @port, *args) }
      self
    end

    # Schedule the asynchronous shutdown of the server binding.
    def stop
      EM.schedule { EM.stop_server(@signature) if @signature }
      self
    end

    # Start the reactor. If the reactor is not already running, calling this
    # method will block until EM.stop is called.
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