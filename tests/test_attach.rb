require_relative 'em_test_helper'

class TestAttach < Test::Unit::TestCase
  class EchoServer < EM::Connection
    def receive_data data
      $received_data << data
      send_data data
    end
  end

  class EchoClient < EM::Connection
    def initialize socket
      self.notify_readable = true
      @socket = socket
      @socket.write("abc\n")
    end

    def notify_readable
      $read = @socket.readline
      $fd = detach
    end

    def unbind
      EM.next_tick do
        @socket.write("def\n")
        EM.add_timer(0.1) { EM.stop }
      end
    end
  end

  def setup
    @port = next_port
    $read, $r, $w, $fd = nil
    $received_data = ""
  end

  def teardown
    [$r, $w].each do |io|
      io.close rescue nil
    end
    $received_data = nil
  end

  def test_attach
    socket = nil

    EM.run {
      EM.start_server "127.0.0.1", @port, EchoServer
      socket = TCPSocket.new "127.0.0.1", @port
      EM.watch socket, EchoClient, socket
    }

    assert_equal $read, "abc\n"
    unless jruby? # jruby filenos are not real
      assert_equal $fd, socket.fileno
    end
    assert_equal false, socket.closed?
    assert_equal socket.readline, "def\n"
  end

  module PipeWatch
    def notify_readable
      $read = $r.readline
      EM.stop
    end
  end

  def test_attach_server
    omit_if(jruby?)
    $before = TCPServer.new("127.0.0.1", @port)
    sig     = nil
    EM.run {
      sig = EM.attach_server $before, EchoServer

      handler = Class.new(EM::Connection) do
        def initialize
          send_data "hello world"
          close_connection_after_writing
          EM.add_timer(0.1) { EM.stop }
        end
      end
      EM.connect("127.0.0.1", @port, handler)
    }

    assert_equal false, $before.closed?
    assert_equal "hello world", $received_data
    assert sig.is_a?(Integer)
  end

  def test_attach_pipe
    EM.run{
      $r, $w = IO.pipe
      EM.watch $r, PipeWatch do |c|
        c.notify_readable = true
      end
      $w.write("ghi\n")
    }

    assert_equal $read, "ghi\n"
  end

  def test_set_readable
    before, after = nil

    EM.run{
      $r, $w = IO.pipe
      c = EM.watch $r, PipeWatch do |con|
        con.notify_readable = false
      end

      EM.next_tick{
        before = c.notify_readable?
        c.notify_readable = true
        after = c.notify_readable?
      }

      $w.write("jkl\n")
    }

    assert !before
    assert after
    assert_equal $read, "jkl\n"
  end

  def test_read_write_pipe
    result = nil

    pipe_reader = Module.new do
      define_method :receive_data do |data|
        result = data
        EM.stop
      end
    end

    r,w = IO.pipe

    EM.run {
      EM.attach r, pipe_reader
      writer = EM.attach(w)
      writer.send_data 'ghi'

      # XXX: Process will hang in Windows without this line
      writer.close_connection_after_writing
    }

    assert_equal "ghi", result
  ensure
    [r,w].each {|io| io.close rescue nil }
  end

  # This test shows that watch_only? is true for EM.watch
  def test_watch_only
    r, w = IO.pipe
    $watch_only = nil

    EM.run do
      EM.watch r do |c|
        assert_true(c.watch_only?)
        c.notify_readable = true
        def c.receive_data data
          fail('this method should not be called')
        end
        def c.notify_readable
          $watch_only = watch_only?
        end
      end
      w.write 'hello'
      EM.next_tick { EM.stop }
    end

    assert_true($watch_only)
  end

  # This test shows that watch_only? is false for EM.attach
  def test_attach_data
    pend("\nFIXME: Freezes Windows testing as of 2018-07-31") if windows?
    r, w = IO.pipe
    $watch_only = nil
    $read = []

    EM.run do
      EM.attach r do |c|
        assert_false(c.watch_only?)
        def c.receive_data data
          $watch_only = watch_only?
          $read << data
        end
        def c.notify_readable
          fail('this method should not be called')
        end
      end
      w.write 'world'
      EM.next_tick { EM.stop }
    end

    assert_false($watch_only)
    assert_equal('world', $read.first)
  end
end
