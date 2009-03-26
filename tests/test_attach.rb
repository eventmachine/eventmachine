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

$:.unshift "../lib"
require 'eventmachine'
require 'socket'
require 'test/unit'


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
      $sock.write("abc\n")
    end

    def notify_readable
      $read = $sock.readline
      $fd = detach
    end

    def unbind
      EM.next_tick do
        $sock.write("def\n")
        EM.add_timer(0.5){ EM.stop }
      end
    end
  end

  def test_attach
    EM.run{
      EM.start_server Host, Port, EchoServer
      $sock = TCPSocket.new Host, Port
      EM.attach $sock, EchoClient
    }

    assert_equal $read, "abc\n"
    assert_equal $fd, $sock.fileno
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
      EM.attach $r, PipeWatch
      $w.write("ghi\n")
    }

    assert_equal $read, "ghi\n"
  end

  module PipeReader
    def receive_data data
      $read = data
      EM.stop
    end
  end

  def test_read_write_pipe
    EM.run{
      $r, $w = IO.pipe
      EM.attach $r, PipeReader
      writer = EM.attach($w)
      writer.send_data 'ghi'
    }

    assert_equal $read, "ghi"
  end
end