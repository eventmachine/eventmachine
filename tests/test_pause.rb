require 'em_test_helper'

class TestPause < Test::Unit::TestCase
  TestHost = "127.0.0.1"
  TestPort = 9070

  def teardown
    assert(!EM.reactor_running?)
  end

  def test_pause_resume
    server = nil

    s_rx = c_rx = 0

    test_server = Module.new do
      define_method :post_init do
        server = self
      end

      define_method :receive_data do |data|
        s_rx += 1

        EM.add_periodic_timer(0.01) { send_data 'hi' }
        send_data 'hi'

        # pause server, now no outgoing data will actually
        # be sent and no more incoming data will be received
        pause
      end
    end

    test_client = Module.new do
      def post_init
        EM.add_periodic_timer(0.01) do
          send_data 'hello'
        end
      end

      define_method :receive_data do |data|
        c_rx += 1
      end
    end

    EM.run do
      EM.start_server TestHost, TestPort, test_server
      EM.connect TestHost, TestPort, test_client

      EM.add_timer(0.1) do
        assert_equal 1, s_rx
        assert_equal 0, c_rx
        assert server.paused?

        # resume server, queued outgoing and incoming data will be flushed
        server.resume

        assert !server.paused?

        EM.add_timer(0.1) do
          assert server.paused?
          assert s_rx > 1
          assert c_rx > 0
          EM.stop
        end
      end
    end
  end
end
