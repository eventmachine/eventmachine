$:.unshift File.expand_path(File.dirname(__FILE__) + "/../lib")
require 'eventmachine'
require 'socket'
require 'test/unit'

class TestGetSockOpt < Test::Unit::TestCase

  def setup
    assert(!EM.reactor_running?)
  end

  def teardown
    assert(!EM.reactor_running?)
  end

  #-------------------------------------

  def test_get_sock_opt
    test = self
    EM.run do
      EM.connect 'google.com', 80, Module.new {
        define_method :post_init do
          val = get_sock_opt Socket::SOL_SOCKET, Socket::SO_REUSEADDR
          test.assert_equal "\01\0\0\0", val
          EM.stop
        end
      }
    end
  end
end
