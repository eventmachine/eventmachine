$:.unshift File.expand_path(File.dirname(__FILE__) + "/../lib")
require 'eventmachine'
require 'test/unit'
require File.dirname(__FILE__) + '/emtestext/testext'

class TestNativeHooks < Test::Unit::TestCase
  HookTestHost = "127.0.0.1"
  HookTestPort = 12345

  module HookTestServer
    def post_init
      send_data "legit data from the server yo, untouched"
    end
    def receive_data(data)
      $hook_test_received_data = data
      EM.stop
    end
  end

  module HookTestRecvClient
    def initialize
      self.hooks = EmTestext.get_em_hooks(self, nil)
    end
    def receive_data(data)
      $hook_test_received_data = data
      EM.stop
    end
    def unbind
      EM.stop
    end
  end

  module HookTestSendClient
    def initialize
      self.hooks = EmTestext.get_em_hooks(nil, self)
    end
    def post_init
      send_special "legit data from the client yo, untouched"
    end
    def receive_data(data)
    end
  end

  def test_receive_hook
    $hook_test_received_data = nil
    EmTestext.reset
    assert !EmTestext.recv_hook_called
    assert EmTestext.test_data.nil?
    assert EmTestext.real_data.nil?
  
    EM.run {
      EM.start_server(HookTestHost, HookTestPort, HookTestServer)
      EM.connect(HookTestHost, HookTestPort, HookTestRecvClient)
    }
  
    assert EmTestext.recv_hook_called
    assert_equal "zomg manipulated inbound dataz", EmTestext.test_data
    assert_equal "legit data from the server yo, untouched", EmTestext.real_data
  end

  def test_send_hook
    $hook_test_received_data = nil
    EmTestext.reset
    assert !EmTestext.send_hook_called

    EM.run {
      EM.start_server(HookTestHost, HookTestPort, HookTestServer)
      c = EM.connect(HookTestHost, HookTestPort, HookTestSendClient)
      c.hooks.recv_hook_enabled = false
    }

    assert EmTestext.send_hook_called
    assert_equal "zomg manipulated outbound dataz", $hook_test_received_data
  end

  def test_disable_recv_hook
    $hook_test_received_data = nil
    EmTestext.reset
    assert !EmTestext.recv_hook_called

    EM.run {
      EM.start_server(HookTestHost, HookTestPort, HookTestServer)
      c = EM.connect(HookTestHost, HookTestPort, HookTestRecvClient)
      c.hooks.recv_hook_enabled = false
    }

    assert !EmTestext.recv_hook_called
    assert EmTestext.test_data.nil?
    assert EmTestext.real_data.nil?
    assert_equal "legit data from the server yo, untouched", $hook_test_received_data
  end

end