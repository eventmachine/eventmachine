require 'em_test_helper'
require 'socket'

class TestSetSockOpt < Test::Unit::TestCase

  if EM.respond_to? :set_sock_opt
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
          define_method :post_init do
            wanted = 10240
            val = set_sock_opt Socket::SOL_SOCKET, Socket::SO_RCVBUF, wanted
            test.assert_equal 0, val
            val = get_sock_opt Socket::SOL_SOCKET, Socket::SO_RCVBUF
            obtained = val.unpack("L")[0]
            test.assert obtained == wanted || obtained == wanted * 2 # Linux at work
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
