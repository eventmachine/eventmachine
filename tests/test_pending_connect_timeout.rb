require_relative 'em_test_helper'

class TestPendingConnectTimeout < Test::Unit::TestCase

  if EM.respond_to? :get_pending_connect_timeout
    def test_default
      pend('FIXME: EM.get_pending_connect_timeout is broken in pure ruby mode') if pure_ruby_mode?
      EM.run {
        c = EM.connect("127.0.0.1", 54321)
        assert_equal 20.0, c.pending_connect_timeout
        EM.stop
      }
    end

    def test_set_and_get
      pend('FIXME: EM.get_pending_connect_timeout is broken in pure ruby mode') if pure_ruby_mode?
      EM.run {
        c = EM.connect("127.0.0.1", 54321)
        c.pending_connect_timeout = 2.5
        assert_equal 2.5, c.pending_connect_timeout
        EM.stop
      }
    end

    def test_for_real
      pend('FIXME: EM.get_pending_connect_timeout is broken in pure ruby mode') if pure_ruby_mode?
      start, finish = nil

      timeout_handler = Module.new do
        define_method :unbind do
          finish = EM.current_time
          EM.stop
        end
      end

      EM.run {
        setup_timeout 0.4
        EM.heartbeat_interval = 0.1
        start = EM.current_time
        c = EM.connect('192.0.2.0', 54321, timeout_handler)
        c.pending_connect_timeout = 0.2
      }
      # Travis can vary from 0.10 to 0.40
      assert_in_delta(0.25, (finish - start), 0.15)
    end
  else
    warn "EM.pending_connect_timeout not implemented, skipping tests in #{__FILE__}"

    # Because some rubies will complain if a TestCase class has no tests
    def test_em_pending_connect_timeout_not_implemented
      assert true
    end
  end

end
