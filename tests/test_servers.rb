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

$:.unshift "../lib"
require 'eventmachine'
require 'socket'
require 'test/unit'


class TestServers < Test::Unit::TestCase

	Host = "127.0.0.1"
	Port = 9550

	def setup
	end

	def teardown
	end


	class TestStopServer < EM::Connection
		def initialize *args
			super
		end
		def post_init
			# TODO,sucks that this isn't OOPy enough.
			EM.stop_server @server_instance
		end
	end
	def run_test_stop_server
		succeed = false
		err = false
		EM.run {
			sig = EM.start_server(Host, Port)
			EM.defer proc {
				if TCPSocket.new Host, Port
					succeed = true
				end
			}, proc {
				EM.stop_server sig
				EM.defer proc {
					# Wait for the acceptor to die, otherwise
					# we'll probably get a conn-reset instead
					# of a conn-refused.
					sleep 0.1
					begin
						TCPSocket.new Host, Port
					rescue
						err = $!
					end
				}, proc {
					EM.stop
				}
			}
		}
		assert_equal( true, succeed )
		assert_equal( Errno::ECONNREFUSED, err.class )
	end
	def test_stop_server
		5.times {run_test_stop_server}
	end


end


