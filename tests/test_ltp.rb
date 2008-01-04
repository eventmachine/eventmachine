# $Id$
#
# Author:: Francis Cianfrocca (gmail: blackhedd)
# Homepage::  http://rubyeventmachine.com
# Date:: 8 April 2006
# 
# See EventMachine and EventMachine::Connection for documentation and
# usage examples.
#
#----------------------------------------------------------------------------
#
# Copyright (C) 2006-07 by Francis Cianfrocca. All Rights Reserved.
# Gmail: blackhedd
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of either: 1) the GNU General Public License
# as published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version; or 2) Ruby's License.
# 
# See the file COPYING for complete licensing information.
#
#---------------------------------------------------------------------------
#
#
#
#

$:.unshift "../lib"
require 'eventmachine'
require 'socket'
require 'test/unit'

class TestLineAndTextProtocol < Test::Unit::TestCase

    TestHost = "127.0.0.1"
    TestPort = 8905


    #--------------------------------------------------------------------

    class SimpleLineTest < EventMachine::Protocols::LineAndTextProtocol
	def receive_line line
	    @line_buffer << line
	end
    end

    def test_simple_lines
        # THIS TEST CURRENTLY FAILS IN JRUBY.
        assert( RUBY_PLATFORM !~ /java/ )

	lines_received = []
	Thread.abort_on_exception = true
	EventMachine.run {
	    EventMachine.start_server( TestHost, TestPort, SimpleLineTest ) do |conn|
		conn.instance_eval "@line_buffer = lines_received"
	    end
	    EventMachine.add_timer(4) {raise "test timed out"}
	    EventMachine.defer proc {
		t = TCPSocket.new TestHost, TestPort
		t.write [
		    "aaa\n", "bbb\r\n", "ccc\n"
		].join
		t.close
	    }, proc {
		EventMachine.stop
	    }
	}
	assert_equal( %w(aaa bbb ccc), lines_received )
    end

    #--------------------------------------------------------------------

    class SimpleLineTest < EventMachine::Protocols::LineAndTextProtocol
	def receive_error text
	    @error_message << text
	end
    end

    def test_overlength_lines
        # THIS TEST CURRENTLY FAILS IN JRUBY.
        assert( RUBY_PLATFORM !~ /java/ )

	lines_received = []
	Thread.abort_on_exception = true
	EventMachine.run {
	    EventMachine.start_server( TestHost, TestPort, SimpleLineTest ) do |conn|
		conn.instance_eval "@error_message = lines_received"
	    end
	    EventMachine.add_timer(4) {raise "test timed out"}
	    EventMachine.defer proc {
		t = TCPSocket.new TestHost, TestPort
		t.write "a" * (16*1024 + 1)
		t.write "\n"
		t.close
	    }, proc {
		EventMachine.stop
	    }
	}
	assert_equal( ["overlength line"], lines_received )
    end


    #--------------------------------------------------------------------

    class LineAndTextTest < EventMachine::Protocols::LineAndTextProtocol
	def post_init
	end
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
	output = nil
	lines_received = []
	text_received = []
	Thread.abort_on_exception = true
	EventMachine.run {
	    EventMachine.start_server( TestHost, TestPort, LineAndTextTest ) do |conn|
		conn.instance_eval "@lines = lines_received; @text = text_received"
	    end
	    EventMachine.add_timer(2) {raise "test timed out"}
	    EventMachine.defer proc {
		t = TCPSocket.new TestHost, TestPort
		t.puts "Content-length: 400"
		t.puts
		t.write "A" * 400
		output = t.read
		t.close
	    }, proc {
		EventMachine.stop
	    }
	}
	assert_equal( "received 400 bytes", output )
    end

    #--------------------------------------------------------------------


    class BinaryTextTest < EventMachine::Protocols::LineAndTextProtocol
	def post_init
	end
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
	output = nil
	lines_received = []
	text_received = []
	Thread.abort_on_exception = true
	EventMachine.run {
	    EventMachine.start_server( TestHost, TestPort, BinaryTextTest ) do |conn|
		conn.instance_eval "@lines = lines_received; @text = text_received"
	    end
	    EventMachine.add_timer(4) {raise "test timed out"}
	    EventMachine.defer proc {
		t = TCPSocket.new TestHost, TestPort
		t.puts "Content-length: 10000"
		t.write "A" * 10000
		output = t.read
		t.close
	    }, proc {
		EventMachine.stop
	    }
	}
	assert_equal( "received 10000 bytes", output )
    end

    #--------------------------------------------------------------------
end


