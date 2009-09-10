describe "tcp connection" do

  before do
    $test = {}
  end

  module Stub
    def connection_completed; end
    def post_init; end
    def receive_data(data); end
    def unbind; end
  end

  EM::Connection.send :include, Stub

  it "connection_completed works" do
    handler = Module.new do
      def connection_completed
        $test[:connection_completed] = true
        @reactor.stop
      end
    end

    reactor = EM::Reactor.new
    reactor.run {
      c = reactor.connect("google.com", 80, handler)
      c.class.ancestors.should.include?(EM::TCPConnection)
    }
    $test[:connection_completed].should == true
    reactor.release
  end

  it "Connection can take extra arguments in initialize that were passed to Reactor#connect" do
    handler = Module.new do
      def initialize(arg1, arg2)
        $test[:arg1] = arg1
        $test[:arg2] = arg2
        @reactor.stop
      end
    end

    reactor = EM::Reactor.new
    reactor.run {
      c = reactor.connect("google.com", 80, handler, "TEST ARG", "OTHER TEST ARG 2")
      c.class.ancestors.should.include?(EM::TCPConnection)
    }
    $test[:arg1].should == "TEST ARG"
    $test[:arg2].should == "OTHER TEST ARG 2"
    reactor.release
  end

  it "receive_data works" do
    handler = Module.new do
      def connection_completed
        send_data "GET / HTTP/1.1\r\n\r\n"
      end
      def receive_data(data)
        $test[:data] = data
        @reactor.stop
      end
    end

    reactor = EM::Reactor.new
    reactor.run {
      c = reactor.connect("google.com", 80, handler)
      c.class.ancestors.include?(EM::TCPConnection)
    }
    $test[:data].should.be.kind_of(String)
    $test[:data].should.not.be.empty
    reactor.release
  end

  it "unbind is called after close_connection" do
    handler = Module.new do
      def connection_completed
        send_data "GET / HTTP/1.1\r\n\r\n"
      end
      def receive_data(data)
        close_connection
      end
      def unbind
        $test[:unbound] = true
        @reactor.stop
      end
    end

    reactor = EM::Reactor.new
    reactor.run {
      c = reactor.connect("google.com", 80, handler)
      c.class.ancestors.should.include?(EM::TCPConnection)
    }
    $test[:unbound].should == true
    reactor.release
  end

  it "tcp server works" do
    server = Module.new do
      def receive_data(data)
        $test[:server_data] = data
        send_data "moretestingdata321"
      end
    end

    client = Module.new do
      def connection_completed
        send_data "testingdata123"
      end
      def receive_data(data)
        $test[:client_data] = data
        close_connection
      end
      def unbind
        @reactor.stop
      end
    end

    reactor = EM::Reactor.new
    reactor.run {
      s = reactor.start_server("127.0.0.1", 9999, server)
      c = reactor.connect("127.0.0.1", 9999, client)
      s.class.should == EM::TCPServer
      c.class.ancestors.should.include?(EM::TCPConnection)
    }
    $test[:server_data].should == "testingdata123"
    $test[:client_data].should == "moretestingdata321"
    reactor.release
  end

  it "server can accept extra args from Reactor#start_server for initialize" do
    server = Module.new do
      def initialize(arg1, arg2, arg3, arg4)
        $test[:arg1] = arg1
        $test[:arg2] = arg2
        $test[:arg3] = arg3
        $test[:arg4] = arg4
        @reactor.stop
      end
    end
    reactor = EM::Reactor.new
    reactor.run {
      s = reactor.start_server("127.0.0.1", 9999, server, "foo", "bar", "baz", "eggology")
      c = reactor.connect("127.0.0.1", 9999)
      s.class.should == EM::TCPServer
      c.class.ancestors.should.include?(EM::TCPConnection)
    }
    $test[:arg1].should == "foo"
    $test[:arg2].should == "bar"
    $test[:arg3].should == "baz"
    $test[:arg4].should == "eggology"
    reactor.release
  end

  it "get_peername should work" do
    server = Module.new do
      def post_init
        $test[:server] = get_peername
      end
    end
    client = Module.new do
      def connection_completed
        @reactor.next_tick {
          $test[:client] = get_peername
          @reactor.stop
        }
      end
    end
    reactor = EM::Reactor.new
    reactor.run {
      s = reactor.start_server("127.0.0.1", 12345, server)
      c = reactor.connect("127.0.0.1", 12345, client)
      s.class.should == EM::TCPServer
      c.class.ancestors.should.include?(EM::TCPConnection)
    }
    $test[:server][0].should == "127.0.0.1"
    $test[:server][1].kind_of?(Integer).should == true
    $test[:client].should == ["127.0.0.1", 12345]
    reactor.release
  end
  
  it "get_sockname should work" do
    server = Module.new do
      def post_init
        $test[:server] = get_sockname
      end
    end
    client = Module.new do
      def connection_completed
        @reactor.next_tick {
          $test[:client] = get_peername
          @reactor.stop
        }
      end
    end
    reactor = EM::Reactor.new
    reactor.run {
      s = reactor.start_server("127.0.0.1", 12345, server)
      c = reactor.connect("127.0.0.1", 12345, client)
      s.class.should == EM::TCPServer
      c.class.ancestors.should.include?(EM::TCPConnection)
    }
    $test[:server].should == ["127.0.0.1", 12345]
    $test[:client][0].should == "127.0.0.1"
    $test[:client][1].kind_of?(Integer).should == true
  end

end