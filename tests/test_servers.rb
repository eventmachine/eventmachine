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
require 'socket'

class TestServers < Test::Unit::TestCase

  Host = "127.0.0.1"
  Port = 9555

  def server_alive?(host=Host, port=Port)
    s = TCPSocket.new( host, port )
    s.close
    s
  rescue Errno::ECONNREFUSED
    false
  end

  def run_test_stop_server
    EM.run {
      sig = EM.start_server(Host, Port)
      assert server_alive?, "Server didn't start"
      EM.stop_server sig
      # Give the server some time to shutdown.
      EM.add_timer(0.1) {
        assert !server_alive?, "Server didn't stop"
        EM.stop
      }
    }
  end

  def test_stop_server
    assert !server_alive?, "Port already in use"
    2.times { run_test_stop_server }
    assert !server_alive?, "Servers didn't stop"
  end

end
