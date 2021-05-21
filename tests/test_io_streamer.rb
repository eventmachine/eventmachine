# frozen_string_literal: true

require_relative 'em_test_helper'
require 'em/io_streamer'
require 'stringio'

# below to stop 'already initialized constant' warning
EM::IOStreamer.__send__ :remove_const, :CHUNK_SIZE
EM::IOStreamer.const_set :CHUNK_SIZE, 2

class TestIOStreamer < Test::Unit::TestCase

  class StreamServer < EM::Connection
    def initialize(sent)
      @sent = sent
    end

    def post_init
      io = StringIO.new @sent
      EM::IOStreamer.new(self, io).callback { close_connection_after_writing }
    end
  end

  class StreamClient < EM::Connection
    def initialize(received)
      @received = received
    end

    def receive_data data
      @received << data
    end

    def unbind
      EM.stop
    end
  end

  def test_io_stream
    sent = 'this is a test'
    received = ''.dup
    EM.run do
      port = next_port
      EM.start_server '127.0.0.1', port, StreamServer, sent
      EM.connect '127.0.0.1', port, StreamClient, received
    end
    assert_equal sent, received
  end
end
