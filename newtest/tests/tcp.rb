describe "tcp connection" do
  it "connection_completed should work" do
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
  
  it "blah" do
    module Handler
      def connection_completed
        send_data "GET / HTTP/1.1\r\n\r\n"
      end
      def receive_data(data)
        p data
        @reactor.stop
      end
    end
    
    @reactor = EM::Reactor.new
    @reactor.run {
      @c = @reactor.connect("google.com", 80, Handler)
    }
    true.should.equal true    
  end
  
end