require 'em_test_helper'
require 'em/io_streamer'

EM::IOStreamer::CHUNK_SIZE = 2

class TestIOStreamer < Test::Unit::TestCase
  class StreamServer < EM::Connection
    TEST_STRING = 'this is a test'.freeze
    def post_init
      io = StringIO.new(TEST_STRING)
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
    received = ''
    EM.run do
      port = next_port
      EM.start_server '127.0.0.1', port, StreamServer
      EM.connect '127.0.0.1', port, StreamClient, received
    end
    assert_equal(StreamServer::TEST_STRING, received)
  end
end
