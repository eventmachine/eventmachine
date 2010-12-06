require 'em_test_helper'

class TestProxyConnection < Test::Unit::TestCase

  module ProxyConnection
    def initialize(client, request)
      @client, @request = client, request
    end

    def post_init
      EM::enable_proxy(self, @client)
    end

    def connection_completed
      EM.next_tick {
        send_data @request
      }
    end

    def proxy_target_unbound
      $unbound_early = true
      EM.stop
    end

    def unbind
      @client.close_connection_after_writing
    end
  end

  module PartialProxyConnection
    def initialize(client, request, length)
      @client, @request, @length = client, request, length
    end

    def post_init
      EM::enable_proxy(self, @client, 0, @length)
    end

    def receive_data(data)
      $unproxied_data = data
      @client.send_data(data) 
    end

    def connection_completed
      EM.next_tick {
        send_data @request
      }
    end

    def proxy_target_unbound
      $unbound_early = true
      EM.stop
    end

    def proxy_completed
      $proxy_completed = true
    end

    def unbind
      @client.close_connection_after_writing
    end
  end

  module Client
    def connection_completed
      send_data "EventMachine rocks!"
    end

    def receive_data(data)
      $client_data = data
    end

    def unbind
      EM.stop
    end
  end

  module Client2
    include Client
    def unbind; end
  end

  module Server
    def receive_data(data)
      send_data "I know!" if data == "EventMachine rocks!"
      close_connection_after_writing
    end
  end

  module ProxyServer
    def receive_data(data)
      EM.connect("127.0.0.1", 54321, ProxyConnection, self, data)
    end
  end

  module PartialProxyServer
    def receive_data(data)
      EM.connect("127.0.0.1", 54321, PartialProxyConnection, self, data, 1)
    end
  end

  module EarlyClosingProxy
    def receive_data(data)
      EM.connect("127.0.0.1", 54321, ProxyConnection, self, data)
      close_connection
    end
  end

  def test_proxy_connection
    EM.run {
      EM.start_server("127.0.0.1", 54321, Server)
      EM.start_server("127.0.0.1", 12345, ProxyServer)
      EM.connect("127.0.0.1", 12345, Client)
    }

    assert_equal("I know!", $client_data)
  end

  def test_partial_proxy_connection
    EM.run {
      EM.start_server("127.0.0.1", 54321, Server)
      EM.start_server("127.0.0.1", 12345, PartialProxyServer)
      EM.connect("127.0.0.1", 12345, Client)
    }

    assert_equal("I know!", $client_data)
    assert_equal(" know!", $unproxied_data)
    assert($proxy_completed)
  end

  def test_early_close
    $client_data = nil
    EM.run {
      EM.start_server("127.0.0.1", 54321, Server)
      EM.start_server("127.0.0.1", 12345, EarlyClosingProxy)
      EM.connect("127.0.0.1", 12345, Client2)
    }

    assert($unbound_early)
  end

end
