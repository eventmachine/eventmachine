require_relative 'em_test_helper'

class TestPause < Test::Unit::TestCase
  if EM.respond_to? :pause_connection
    def setup
      @port = next_port
    end

    def teardown
      assert(!EM.reactor_running?)
    end

    def test_pause_resume
      pend('FIXME: EM.pause_connection is broken in pure ruby mode') if pure_ruby_mode?
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
        EM.start_server "127.0.0.1", @port, test_server
        EM.connect "127.0.0.1", @port, test_client

        tmr = darwin? ? 0.25 : 0.05

        EM.add_timer(tmr) do
          assert_equal 1, s_rx
          assert_equal 0, c_rx
          assert server.paused?

          # resume server, queued outgoing and incoming data will be flushed
          server.resume

          assert !server.paused?

          EM.add_timer(tmr) do
            assert server.paused?
            assert s_rx > 1
            assert c_rx > 0
            EM.stop
          end
        end
      end
    end

    def test_pause_in_receive_data
      pend('FIXME: EM.pause_connection is broken in pure ruby mode') if pure_ruby_mode?
      incoming = []

      test_server = Module.new do
        define_method(:receive_data) do |data|
          incoming << data
          pause
          EM.add_timer(0.5){ close_connection }
        end
        define_method(:unbind) do
          EM.stop
        end
      end

      buf = 'a' * 1024

      EM.run do
        EM.start_server "127.0.0.1", @port, test_server
        cli = EM.connect "127.0.0.1", @port
        128.times do
          cli.send_data buf
        end
      end

      assert_equal 1, incoming.size
      assert incoming[0].bytesize > buf.bytesize
      assert incoming[0].bytesize < buf.bytesize * 128
    end
  else
    warn "EM.pause_connection not implemented, skipping tests in #{__FILE__}"

    # Because some rubies will complain if a TestCase class has no tests
    def test_em_pause_connection_not_implemented
      assert true
    end
  end
end
