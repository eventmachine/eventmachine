# frozen_string_literal: true

require_relative 'em_test_helper'

class TestBasic < Test::Unit::TestCase
  def setup
    @port = next_port
  end

  INVALID = "(not known|no data of the requested|No such host is known|Temporary failure in name resolution)"

  def test_connection_class_cache
    mod = Module.new
    a, b = nil, nil
    EM.run {
      EM.start_server '127.0.0.1', @port, mod
      a = EM.connect '127.0.0.1', @port, mod
      b = EM.connect '127.0.0.1', @port, mod
      EM.stop
    }
    assert_equal a.class, b.class
    assert_kind_of EM::Connection, a
  end

  #-------------------------------------

  def test_em
    assert_nothing_raised do
      EM.run {
        setup_timeout
        EM.add_timer 0 do
          EM.stop
        end
      }
    end
  end

  #-------------------------------------

  def test_timer
    assert_nothing_raised do
      EM.run {
        setup_timeout(TIMEOUT_INTERVAL * 2)
        n = 0
        EM.add_periodic_timer(0.1) {
          n += 1
          EM.stop if n == 2
        }
      }
    end
  end

  #-------------------------------------

  # This test once threw an already-running exception.
  module Trivial
    def post_init
      EM.stop
    end
  end

  def test_server
    assert_nothing_raised do
      EM.run {
        setup_timeout
        EM.start_server "127.0.0.1", @port, Trivial
        EM.connect "127.0.0.1", @port
      }
    end
  end

  #--------------------------------------

  # EM#run_block starts the reactor loop, runs the supplied block, and then STOPS
  # the loop automatically. Contrast with EM#run, which keeps running the reactor
  # even after the supplied block completes.
  def test_run_block
    assert !EM.reactor_running?
    a = nil
    EM.run_block { a = "Worked" }
    assert a
    assert !EM.reactor_running?
  end

  class UnbindError < EM::Connection
    ERR = Class.new(StandardError)
    def initialize *args
      super
    end
    def connection_completed
      close_connection_after_writing
    end
    def unbind
      raise ERR
    end
  end

  def test_unbind_error_during_stop
    pend('FIXME: This test is broken in pure ruby mode') if pure_ruby_mode?
    assert_raises( UnbindError::ERR ) {
      EM.run {
        EM.start_server "127.0.0.1", @port
        EM.connect "127.0.0.1", @port, UnbindError do
          EM.stop
        end
      }
    }
  end

  def test_unbind_error
    EM.run {
      EM.error_handler do |e|
        assert(e.is_a?(UnbindError::ERR))
        EM.stop
      end
      EM.start_server "127.0.0.1", @port
      EM.connect "127.0.0.1", @port, UnbindError
    }

    # Remove the error handler before the next test
    EM.error_handler(nil)
  end

  module BrsTestSrv
    def receive_data data
      $received << data
    end
    def unbind
      EM.stop
    end
  end
  module BrsTestCli
    def post_init
      send_data $sent
      close_connection_after_writing
    end
  end

  # From ticket #50
  def test_byte_range_send
    $received = ''.dup
    $sent = (0..255).to_a.pack('C*')
    EM::run {
      EM::start_server "127.0.0.1", @port, BrsTestSrv
      EM::connect "127.0.0.1", @port, BrsTestCli

      setup_timeout
    }
    assert_equal($sent, $received)
  end

  def test_bind_connect
    local_ip = UDPSocket.open {|s| s.connect('localhost', 80); s.addr.last }

    bind_port = next_port

    port, ip = nil
    bound_server = Module.new do
      define_method :post_init do
        begin
          port, ip = Socket.unpack_sockaddr_in(get_peername)
        ensure
          EM.stop
        end
      end
    end

    EM.run do
      setup_timeout
      EM.start_server "127.0.0.1", @port, bound_server
      EM.bind_connect local_ip, bind_port, "127.0.0.1", @port
    end

    assert_equal bind_port, port
    assert_equal local_ip, ip
  end

  def test_invalid_address_bind_connect_dst
    pend('FIXME: A different error is raised in pure ruby mode') if pure_ruby_mode?
    pend("\nFIXME: Windows as of 2018-06-23 on 32 bit >= 2.4 (#{RUBY_VERSION} #{RUBY_PLATFORM})") if RUBY_PLATFORM[/i386-mingw/] && RUBY_VERSION >= '2.4'
    e = nil
    EM.run do
      begin
        EM.bind_connect('localhost', nil, 'invalid.invalid', 80)
      rescue Exception => e
        # capture the exception
      ensure
        EM.stop
      end
    end

    assert_kind_of(EventMachine::ConnectionError, e)
    assert_match(/unable to resolve address:.*#{INVALID}/, e.message)
  end

  def test_invalid_address_bind_connect_src
    pend('FIXME: A different error is raised in pure ruby mode') if pure_ruby_mode?
    pend("\nFIXME: Windows as of 2018-06-23 on 32 bit >= 2.4 (#{RUBY_VERSION} #{RUBY_PLATFORM})") if RUBY_PLATFORM[/i386-mingw/] && RUBY_VERSION >= '2.4'
    e = nil
    EM.run do
      begin
        EM.bind_connect('invalid.invalid', nil, 'localhost', 80)
      rescue Exception => e
        # capture the exception
      ensure
        EM.stop
      end
    end

    assert_kind_of(EventMachine::ConnectionError, e)
    assert_match(/invalid bind address:.*#{INVALID}/, e.message)
  end

  def test_reactor_thread?
    assert !EM.reactor_thread?
    EM.run { assert EM.reactor_thread?; EM.stop }
    assert !EM.reactor_thread?
  end

  def test_schedule_on_reactor_thread
    x = false
    EM.run do
      EM.schedule { x = true }
      EM.stop
    end
    assert x
  end

  def test_schedule_from_thread
    x = false
    EM.run do
      Thread.new { EM.schedule { x = true; EM.stop } }.join
    end
    assert x
  end

  def test_set_heartbeat_interval
    pend('FIXME: EM.set_heartbeat_interval is broken in pure ruby mode') if pure_ruby_mode?
    omit_if(jruby?)
    interval = 0.5
    EM.run {
      EM.set_heartbeat_interval interval
      $interval = EM.get_heartbeat_interval
      EM.stop
    }
    assert_equal(interval, $interval)
  end

  module PostInitRaiser
    ERR = Class.new(StandardError)
    def post_init
      raise ERR
    end
  end

  def test_bubble_errors_from_post_init
    assert_raises(PostInitRaiser::ERR) do
      EM.run do
        EM.start_server "127.0.0.1", @port
        EM.connect "127.0.0.1", @port, PostInitRaiser
      end
    end
  end

  module InitializeRaiser
    ERR = Class.new(StandardError)
    def initialize
      raise ERR
    end
  end

  def test_bubble_errors_from_initialize
    assert_raises(InitializeRaiser::ERR) do
      EM.run do
        EM.start_server "127.0.0.1", @port
        EM.connect "127.0.0.1", @port, InitializeRaiser
      end
    end
  end

  def test_schedule_close
    pend('FIXME: EM.num_close_scheduled is broken in pure ruby mode') if pure_ruby_mode?
    omit_if(jruby?)
    localhost, port = '127.0.0.1', 9000
    timer_ran = false
    num_close_scheduled = nil
    EM.run do
      assert_equal 0, EM.num_close_scheduled
      EM.add_timer(1) { timer_ran = true; EM.stop }
      EM.start_server localhost, port do |s|
        s.close_connection
        num_close_scheduled = EM.num_close_scheduled
      end
      EM.connect localhost, port do |c|
        def c.unbind
          EM.stop
        end
      end
    end
    assert !timer_ran
    assert_equal 1, num_close_scheduled
  end

  def test_error_handler_idempotent # issue 185
    pend('FIXME: EM.error_handler is broken in pure ruby mode') if pure_ruby_mode?
    errors = []
    ticks = []
    EM.error_handler do |e|
      errors << e
    end

    EM.run do
      EM.next_tick do
        ticks << :first
        raise
      end
      EM.next_tick do
        ticks << :second
      end
      EM.add_timer(0.001) { EM.stop }
    end

    # Remove the error handler before the next test
    EM.error_handler(nil)

    assert_equal 1, errors.size
    assert_equal [:first, :second], ticks
  end
end
