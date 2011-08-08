require 'em_test_helper'

class TestLineAndTextProtocol < Test::Unit::TestCase

  class SimpleLineTest < EM::P::LineAndTextProtocol
    def receive_line line
      @line_buffer << line
    end
  end

  module StopClient
    def set_receive_data(&blk)
      @rdb = blk
    end

    def receive_data data
      @rdb.call(data) if @rdb
    end

    def unbind
      EM.add_timer(0.1) { EM.stop }
    end
  end

  def setup
    @port = next_port
  end

  def test_simple_lines
    lines_received = []
    EM.run {
      EM.start_server( "127.0.0.1", @port, SimpleLineTest ) do |conn|
        conn.instance_eval "@line_buffer = lines_received"
      end
      setup_timeout

      EM.connect "127.0.0.1", @port, StopClient do |c|
        c.send_data "aaa\nbbb\r\nccc\n"
        c.close_connection_after_writing
      end
    }
    assert_equal( %w(aaa bbb ccc), lines_received )
  end

  #--------------------------------------------------------------------

  class SimpleLineTest < EM::P::LineAndTextProtocol
    def receive_error text
      @error_message << text
    end
  end

  def test_overlength_lines
    lines_received = []
    EM.run {
      EM.start_server( "127.0.0.1", @port, SimpleLineTest ) do |conn|
        conn.instance_eval "@error_message = lines_received"
      end
      setup_timeout

      EM.connect "127.0.0.1", @port, StopClient do |c|
        c.send_data "a" * (16*1024 + 1)
        c.send_data "\n"
        c.close_connection_after_writing
      end

    }
    assert_equal( ["overlength line"], lines_received )
  end


  #--------------------------------------------------------------------

  class LineAndTextTest < EM::P::LineAndTextProtocol
    def receive_line line
      if line =~ /content-length:\s*(\d+)/i
        @content_length = $1.to_i
      elsif line.length == 0
        set_binary_mode @content_length
      end
    end
    def receive_binary_data text
      send_data "received #{text.length} bytes"
      close_connection_after_writing
    end
  end

  def test_lines_and_text
    output = ''
    EM.run {
      EM.start_server( "127.0.0.1", @port, LineAndTextTest )
      setup_timeout

      EM.connect "127.0.0.1", @port, StopClient do |c|
        c.set_receive_data { |data| output << data }
        c.send_data "Content-length: 400\n"
        c.send_data "\n"
        c.send_data "A" * 400
        EM.add_timer(0.1) { c.close_connection_after_writing }
      end
    }
    assert_equal( "received 400 bytes", output )
  end

  #--------------------------------------------------------------------


  class BinaryTextTest < EM::P::LineAndTextProtocol
    def receive_line line
      if line =~ /content-length:\s*(\d+)/i
        set_binary_mode $1.to_i
      else
        raise "protocol error"
      end
    end
    def receive_binary_data text
      send_data "received #{text.length} bytes"
      close_connection_after_writing
    end
  end

  def test_binary_text
    output = ''
    EM.run {
      EM.start_server( "127.0.0.1", @port, BinaryTextTest )
      setup_timeout

      EM.connect "127.0.0.1", @port, StopClient do |c|
        c.set_receive_data { |data| output << data }
        c.send_data "Content-length: 10000\n"
        c.send_data "A" * 10000
        EM.add_timer(0.1) { c.close_connection_after_writing }
      end
    }
    assert_equal( "received 10000 bytes", output )
  end

end
