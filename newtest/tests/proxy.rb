describe "Proxy" do

  before do
    $test = {}
  end

  module Stub
    def connection_completed; end
    def receive_data(data); end
    def unbind; end
  end

  EM::Connection.send :include, Stub

  module ProxyConnection
    def initialize(client, request)
      @client, @request = client, request
      proxy_incoming_to(@client)
    end

    def connection_completed
      @reactor.next_tick {
        send_data @request
      }
    end

    def proxy_target_unbound
      $test[:unbound_early] = true
      @reactor.stop
    end

    def unbind
      @client.close_connection(true)
    end
  end

  module Client
    def connection_completed
      send_data "EventMachine rocks!"
    end

    def receive_data(data)
      $test[:client_data] = data
    end

    def unbind
      @reactor.stop
    end
  end

  module Client2
    include Client
    def unbind; end
  end

  module Server
    def receive_data(data)
      send_data "I know!" if data == "EventMachine rocks!"
      close_connection(true)
    end
  end

  module ProxyServer
    def receive_data(data)
      @reactor.connect("127.0.0.1", 54321, ProxyConnection, self, data)
    end
  end

  module EarlyClosingProxy
    def receive_data(data)
      @reactor.connect("127.0.0.1", 54321, ProxyConnection, self, data)
      close_connection
    end
  end

  it "normal proxy test" do
    reactor = EM::Reactor.new
    reactor.run {
      reactor.start_server("127.0.0.1", 54321, Server)
      reactor.start_server("127.0.0.1", 12345, ProxyServer)
      reactor.connect("127.0.0.1", 12345, Client)
    }

    $test[:client_data].should == "I know!"
    reactor.release
  end

  it "proxy that closes connection early (proxy_target_unbound)" do
    $test[:client_data] = nil
    reactor = EM::Reactor.new
    reactor.run {
      reactor.start_server("127.0.0.1", 54321, Server)
      reactor.start_server("127.0.0.1", 12345, EarlyClosingProxy)
      reactor.connect("127.0.0.1", 12345, Client2)
    }

    $test[:unbound_early].should == true
    reactor.release
  end

end
