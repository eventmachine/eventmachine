require "test/unit"

require "eventmachine"

class TestEventmachineServer < Test::Unit::TestCase
  module UnbindStopper
    def unbind
      EM.next_tick { EM.stop }
    end
  end

  module ImmediateCloser
    def connection_completed
      close_connection
    end
  end

  module ClosingStopper
    include ImmediateCloser
    include UnbindStopper
  end

  attr_reader :localhost, :port

  def setup
    @localhost, @port = '127.0.0.1', 10000 + rand(1000)
  end

  def job(&blk)
    EM.next_tick(&blk)
  end
  
  def in_ticks(n = 3, &b)
    if n == 0
      yield
    else
      job { in_ticks(n - 1, &b) }
    end
  end

  # The block passed to go here will be added as a next_tick in order to
  # preserve execution order for any predefined jobs in the next_tick queue.
  def go(timeout = 1, &blk)
    job(&blk) if blk
    success = true
    EM.run do
      EM.add_timer(timeout) do
        EM.stop
        success = false
      end
    end
    assert success, "Timedout after #{timeout} seconds"
  end

  def test_initialize
    assert EM::Server.new(localhost, port)
  end

  def test_listen_with_module
    go do
      EM::Server.new(localhost, port, UnbindStopper).listen
      EM.connect localhost, port, ImmediateCloser
    end
  end

  def test_listen_with_class
    klass = Class.new(EM::Connection) { include UnbindStopper }
    go do
      EM::Server.new(localhost, port, klass).listen
      EM.connect localhost, port, ImmediateCloser
    end
  end

  def test_listen_with_block
    go do
      server = EM::Server.new(localhost, port) { include UnbindStopper }
      server.listen
      EM.connect localhost, port, ImmediateCloser
    end
  end

  def test_listen_without_reactor_running_schedules
    EM::Server.new(localhost, port, UnbindStopper).listen
    go { EM.connect localhost, port, ImmediateCloser }
  end

  def test_run
    server = EM::Server.new(localhost, port, UnbindStopper).listen
    job { EM.connect localhost, port, ImmediateCloser }
    server.run
  end

  def test_stop
    server = EM::Server.new(localhost, port, EM::Connection).listen.stop
    # We have to belay this a few ticks to allow the machine to asynchronously
    # complete the closing of the listen socket
    go { in_ticks(5) { EM.connect(localhost, port, UnbindStopper) } }
  end

  class Aggregator
    attr_reader :table

    def initialize
      @table = Hash.new { |h,k| h[k] = [] }
    end

    def method_missing(name, *args)
      @table[name] << args
    end
  end

  def test_delegate_connection
    aggregator = Aggregator.new
    server = EM::Server.new(localhost, port, aggregator).listen
    2.times do
      job { EM.connect localhost, port, ImmediateCloser }
    end
    go { EM.connect localhost, port, ClosingStopper }
    # TODO independently test the rest of the methods are delegated correctly
    assert_equal 3, aggregator.table[:init].size
    assert_equal 3, aggregator.table[:unbind].size
  end
end