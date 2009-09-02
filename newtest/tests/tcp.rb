describe "tcp connection" do

  it "connection_completed should work and so should initialize args" do
    module Handler
      def initialize(reactor)
        @foo = reactor
      end
      def connection_completed
        $completed = true
        @foo.stop
      end
    end
    @reactor = EM::Reactor.new
    @reactor.run {
      @c = @reactor.connect("google.com", 80, Handler, @reactor)
    }
    $completed.should.equal true
  end

  it "receive_data and unbind should work" do
    module Handler
      def connection_completed
        send_data "GET / HTTP/1.1\r\n\r\n"
      end
      def receive_data(data)
        $data_received = true
        close_connection
      end
      def unbind
        $unbound = true
        @reactor.stop
      end
    end

    @reactor = EM::Reactor.new
    @reactor.run {
      @c = @reactor.connect("google.com", 80, Handler)
    }

    $data_received.should.equal true
    $unbound.should.equal true
  end
  
  it "acceptor works, with args" do
    
    module Server
      def initialize(foo, bar)
        $ARG1 = foo
        $ARG2 = bar
      end
      def receive_data(data)
        $serverdata = data
        send_data "moretesting"
      end
    end
    
    module Client
      def connection_completed
        send_data "testing"
      end
      def receive_data(data)
        $clientdata = data
        close_connection
      end
      def unbind
        @reactor.stop
      end
      
    end
    
    @reactor = EM::Reactor.new
    @reactor.run {
      @reactor.start_server("127.0.0.1", 9999, Server, "YAKI", "SCHLOBA")
      @reactor.connect("127.0.0.1", 9999, Client)
    }
    
    $serverdata.should.equal "testing"
    $clientdata.should.equal "moretesting"
    $ARG1.should.equal "YAKI"
    $ARG2.should.equal "SCHLOBA"
  end

end