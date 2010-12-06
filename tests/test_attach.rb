# $Id$
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

require 'em_test_helper'
require 'socket'

class TestAttach < Test::Unit::TestCase

  Host = "127.0.0.1"
  Port = 9550

  class EchoServer < EM::Connection
    def receive_data data
      send_data data
    end
  end

  class EchoClient < EM::Connection
    def initialize
      self.notify_readable = true
      $sock.write("abc\n")
    end

    def notify_readable
      $read = $sock.readline
      $fd = detach
    end

    def unbind
      EM.next_tick do
        $sock.write("def\n")
        EM.add_timer(0.1){ EM.stop }
      end
    end
  end

  def setup
    $read, $write, $sock, $r, $w, $fd, $sock, $before, $after = nil
  end

  def teardown
    [$read, $write, $sock, $r, $w, $fd, $sock, $before, $after].each do |io|
      io.close rescue nil
    end
  end

  def test_attach
    EM.run{
      EM.start_server Host, Port, EchoServer
      $sock = TCPSocket.new Host, Port
      EM.watch $sock, EchoClient
    }

    assert_equal $read, "abc\n"
    unless defined? JRuby # jruby filenos are not real
      assert_equal $fd, $sock.fileno
    end
    assert_equal false, $sock.closed?
    assert_equal $sock.readline, "def\n"
  end

  module PipeWatch
    def notify_readable
      $read = $r.readline
      EM.stop
    end
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
    EM.run{
      $r, $w = IO.pipe
      c = EM.watch $r, PipeWatch do |con|
        con.notify_readable = false
      end

      EM.next_tick{
        $before = c.notify_readable?
        c.notify_readable = true
        $after = c.notify_readable?
      }

      $w.write("jkl\n")
    }

    assert !$before
    assert $after
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
end
