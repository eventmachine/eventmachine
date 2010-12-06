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

require 'em_test_helper'

class TestHeaderAndContentProtocol < Test::Unit::TestCase

  TestHost = "127.0.0.1"
  TestPort = 8905

  class SimpleTest < EventMachine::Protocols::HeaderAndContentProtocol
    attr_reader :first_header, :my_headers, :request

    def receive_first_header_line hdr
      @first_header ||= []
      @first_header << hdr
    end
    def receive_headers hdrs
      @my_headers ||= []
      @my_headers << hdrs
    end
    def receive_request hdrs, content
      @request ||= []
      @request << [hdrs, content]
    end
  end
  
  class StopOnUnbind < EM::Connection
    def unbind
      EM.add_timer(0.1) { EM.stop }
    end
  end

  def test_no_content
    the_connection = nil
    EM.run {
      EM.start_server( TestHost, TestPort, SimpleTest ) do |conn|
        the_connection = conn
      end
      setup_timeout

      EM.connect TestHost, TestPort, StopOnUnbind do |c|
        c.send_data [ "aaa\n", "bbb\r\n", "ccc\n", "\n" ].join
        c.close_connection_after_writing
      end
    }
    assert_equal( ["aaa"], the_connection.first_header )
    assert_equal( [%w(aaa bbb ccc)], the_connection.my_headers )
    assert_equal( [[%w(aaa bbb ccc), ""]], the_connection.request )
  end

  def test_content
    the_connection = nil
    content = "A" * 50
    headers = ["aaa", "bbb", "Content-length: #{content.length}", "ccc"]
    EventMachine.run {
      EventMachine.start_server( TestHost, TestPort, SimpleTest ) do |conn|
        the_connection = conn
      end
      setup_timeout

      EM.connect TestHost, TestPort, StopOnUnbind do |c|
        headers.each { |h| c.send_data "#{h}\r\n" }
        c.send_data "\n"
        c.send_data content
        c.close_connection_after_writing
      end
    }
    assert_equal( ["aaa"], the_connection.first_header )
    assert_equal( [headers], the_connection.my_headers )
    assert_equal( [[headers, content]], the_connection.request )
  end

  def test_several_requests
    the_connection = nil
    content = "A" * 50
    headers = ["aaa", "bbb", "Content-length: #{content.length}", "ccc"]
    EventMachine.run {
      EventMachine.start_server( TestHost, TestPort, SimpleTest ) do |conn|
        the_connection = conn
      end
      setup_timeout

      EventMachine.connect( TestHost, TestPort, StopOnUnbind ) do |c|
        5.times do
          headers.each { |h| c.send_data "#{h}\r\n" }
          c.send_data "\n"
          c.send_data content
        end
        c.close_connection_after_writing
      end
    }
    assert_equal( ["aaa"] * 5, the_connection.first_header )
    assert_equal( [headers] * 5, the_connection.my_headers )
    assert_equal( [[headers, content]] * 5, the_connection.request )
  end


  # def x_test_multiple_content_length_headers
  #   # This is supposed to throw a RuntimeError but it throws a C++ exception instead.
  #   the_connection = nil
  #   content = "A" * 50
  #   headers = ["aaa", "bbb", ["Content-length: #{content.length}"]*2, "ccc"].flatten
  #   EventMachine.run {
  #     EventMachine.start_server( TestHost, TestPort, SimpleTest ) do |conn|
  #       the_connection = conn
  #     end
  #     EventMachine.add_timer(4) {raise "test timed out"}
  #     test_proc = proc {
  #       t = TCPSocket.new TestHost, TestPort
  #       headers.each {|h| t.write "#{h}\r\n" }
  #       t.write "\n"
  #       t.write content
  #       t.close
  #     }
  #     EventMachine.defer test_proc, proc {
  #       EventMachine.stop
  #     }
  #   }
  # end

  def test_interpret_headers
    the_connection = nil
    content = "A" * 50
    headers = [
      "GET / HTTP/1.0",
      "Accept: aaa",
      "User-Agent: bbb",
      "Host: ccc",
      "x-tempest-header:ddd"
    ]

    EventMachine.run {
      EventMachine.start_server( TestHost, TestPort, SimpleTest ) do |conn|
        the_connection = conn
      end
      setup_timeout

      EventMachine.connect( TestHost, TestPort, StopOnUnbind ) do |c|
        headers.each { |h| c.send_data "#{h}\r\n" }
        c.send_data "\n"
        c.send_data content
        c.close_connection_after_writing
      end
    }

    hsh = the_connection.headers_2_hash( the_connection.my_headers.shift )
    expect = {
      :accept => "aaa",
      :user_agent => "bbb",
      :host => "ccc",
      :x_tempest_header => "ddd"
    }
    assert_equal(expect, hsh)
  end

end
