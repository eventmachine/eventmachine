require_relative 'em_test_helper'

class TestInactivityTimeout < Test::Unit::TestCase

  if EM.respond_to? :get_comm_inactivity_timeout
    def test_default
      EM.run {
        c = EM.connect("127.0.0.1", 54321)
        assert_equal 0.0, c.comm_inactivity_timeout
        EM.stop
      }
    end

    def test_set_and_get
      EM.run {
        c = EM.connect("127.0.0.1", 54321)
        c.comm_inactivity_timeout = 2.5
        assert_equal 2.5, c.comm_inactivity_timeout
        EM.stop
      }
    end

    def test_for_real
      start, finish, reason = nil

      timeout_start = Module.new do
        define_method :post_init do
          start = Time.now
        end
      end

      timeout_handler = Module.new do
        define_method :unbind do
          finish = Time.now
          EM.stop
        end
      end

      EM.run {
        setup_timeout 0.4
        EM.heartbeat_interval = 0.01
        EM.start_server("127.0.0.1", 12345, timeout_start)
        EM.add_timer(0.01) {
          c = EM.connect("127.0.0.1", 12345, timeout_handler)
          c.comm_inactivity_timeout = 0.02
        }
      }
      # Travis can vary from 0.02 to 0.17, Appveyor maybe as low as 0.01
      assert_in_delta 0.09, (finish - start), (darwin? ? 0.10 : 0.08)

      # simplified reproducer for comm_inactivity_timeout taking twice as long
      # as requested -- https://github.com/eventmachine/eventmachine/issues/554
      timeout_start_tls = Module.new do
        define_method :post_init do
          start = Time.now
          start_tls
        end
        define_method :receive_data do |data|
          send_data ">>>you sent: #{data}"
        end
      end

      timeout_handler_tls = Module.new do
        define_method :connection_completed do
          start_tls
        end

        define_method :ssl_handshake_completed do
          @timer = EM::PeriodicTimer.new(0.05) do
            #puts "get_idle_time: #{get_idle_time} inactivity: #{comm_inactivity_timeout}"
          end
          send_data "hello world"
        end

        define_method :unbind do |r|
          finish = Time.now
          reason = r
          EM.stop
        end
      end

      EM.run {
        setup_timeout 1.4
        EM.start_server("127.0.0.1", 12345, timeout_start_tls)
        c = EM.connect("127.0.0.1", 12345, timeout_handler_tls)
        c.comm_inactivity_timeout = 0.15
      }

      # .30 is double the timeout and not acceptable
      assert_in_delta 0.15, (finish - start), (darwin? ? 0.20 : 0.14)
      # make sure it was a timeout and not a TLS error
      assert_equal Errno::ETIMEDOUT, reason
    end
  else
    warn "EM.comm_inactivity_timeout not implemented, skipping tests in #{__FILE__}"

    # Because some rubies will complain if a TestCase class has no tests
    def test_em_comm_inactivity_timeout_not_implemented
      assert true
    end
  end
end
