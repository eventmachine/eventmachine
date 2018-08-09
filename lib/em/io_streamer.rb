require 'em/streamer'

# Streams an IO object over a given connection. Streaming begins once the object is
# instantiated. Typically IOStreamer instances are not reused.  IOStreamer includes
# a 16K buffer.  If streaming from a file, FileStreamer is more efficient.
#
# @example
#
#  module FileSender
#    def post_init
# @example
#
#  module SocketSender
#      socket = TCPSocket.new('localhost', 2000)
#      streamer = EventMachine::IOStreamer.new(self, socket)
#      streamer.callback{
#        # all data was sent successfully
#        close_connection_after_writing
#      }
#    end
#  end

# Stream from any IO object, similar to FileStreamer
module EventMachine
  class IOStreamer
    include Deferrable
    CHUNK_SIZE = 16384

    # @param [EventMachine::Connection] connection
    # @param [IO] io Data source
    #
    # @option opts [Boolean] :http_chunks (false) Use HTTP 1.1 style chunked-encoding semantics.
    def initialize(connection, io, opts = {})
      @connection = connection
      @io = io
      @http_chunks = opts[:http_chunks]

      @buff = String.new
      @io.binmode if @io.respond_to?(:binmode)
      stream_one_chunk
    end

  private

    # Used internally to stream one chunk at a time over multiple reactor ticks
    # @private
    def stream_one_chunk
      loop do
        if @io.eof?
          @connection.send_data "0\r\n\r\n" if @http_chunks
          succeed
          break
        end

        if @connection.respond_to?(:get_outbound_data_size) && (@connection.get_outbound_data_size > FileStreamer::BackpressureLevel)
          EventMachine::next_tick { stream_one_chunk }
          break
        end

        if @io.read(CHUNK_SIZE, @buff)
          @connection.send_data("#{@buff.length.to_s(16)}\r\n") if @http_chunks
          @connection.send_data(@buff)
          @connection.send_data("\r\n") if @http_chunks
        end
      end
    end
  end
end
