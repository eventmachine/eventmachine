require "test/unit"
require "eventmachine"

class TestDelegateConnection < Test::Unit::TestCase
  include EM::Test

  class Aggregator
    attr_reader :table

    def initialize
      @table = Hash.new { |h,k| h[k] = [] }
    end

    def method_missing(name, *args)
      @table[name] << args
    end
  end

  def test_delegate_connection_with_server
    localhost, port = '127.0.0.1', 10000+rand(500)
    aggregator = Aggregator.new
    server = EM::Server.new(localhost, port, aggregator).listen
    2.times do
      job { EM.connect localhost, port, ImmediateCloser }
    end
    go { EM.connect localhost, port, ClosingStopper }
    assert_equal 3, aggregator.table[:init].size
    assert_equal 3, aggregator.table[:unbind].size
  end

  def test_parameterless_callbacks
    signature = '12345678'

    tracker = Aggregator.new

    # EM::Connection.new overrides new, and requires a signature parameter
    conn = EM::DelegateConnection.new(signature, tracker)

    assert_equal 1, tracker.table[:init].size

    # Automatically called by EM::Connection.new
    assert_equal 1, tracker.table[:post_init].size

    parameterless_callbacks = %w(
      ssl_handshake_completed unbind proxy_target_unbound connection_completed
    )
    parameterless_callbacks.each do |method|
      conn.__send__ method
      assert_equal 1, tracker.table[method.to_sym].size
    end

  end

  def test_parametered_callbacks
    signature = '12345678'

    tracker = Aggregator.new

    # EM::Connection.new overrides new, and requires a signature parameter
    conn = EM::DelegateConnection.new(signature, tracker)

    conn.receive_data("rubyfoo")
    assert_equal "rubyfoo", tracker.table[:receive_data].first.last

    conn.ssl_verify_peer("some cert")
    assert_equal "some cert", tracker.table[:ssl_verify_peer].first.last
  end

  def test_ip_port
    localhost, port = '127.0.0.1', 10000+rand(500)
    aggregator = Aggregator.new
    server = EM::Server.new(localhost, port, aggregator).listen

    assertions = lambda {
      assert_equal localhost, aggregator.table[:init].first.first.ip
      assert_kind_of Integer, aggregator.table[:init].first.first.port
      ip = localhost
      prt = aggregator.table[:init].first.first.port
      assert_equal "#{ip}:#{prt}", aggregator.table[:init].first.first.ip_port
    }

    go do
      EM.connect localhost, port, Module.new {
        define_method(:connection_completed) do
          # Allow reactor callbacks for server side of connection by waiting
          # another tick.
          EM.next_tick {
            assertions.call
            EM.stop
          }
        end
      }
    end
  end
end