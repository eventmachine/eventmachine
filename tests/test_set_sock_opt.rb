require 'em_test_helper'
require 'socket'

class TestSetSockOpt < Test::Unit::TestCase

  if EM.respond_to? :set_sock_opt and EM.respond_to? :get_sock_opt
    def setup
      assert(!EM.reactor_running?)
    end

    def teardown
      assert(!EM.reactor_running?)
    end

    #-------------------------------------

    def test_set_sock_opt
      test = self
      EM.run do
        EM.connect 'google.com', 80, Module.new {
          define_method :connection_completed do
            val = get_sock_opt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY).unpack('i').first
            test.assert_not_equal 0, val
            set_sock_opt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 0)
            val = get_sock_opt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY).unpack('i').first
            test.assert_equal 0, val
            EM.stop
          end
        }
      end
    end
  else
    warn "EM.set_sock_opt not implemented, skipping tests in #{__FILE__}"

    # Because some rubies will complain if a TestCase class has no tests
    def test_em_set_sock_opt_unsupported
      assert true
    end
  end
end
