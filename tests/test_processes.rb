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
require 'test/unit'

class TestProcesses < Test::Unit::TestCase

	# EM::DeferrableChildProcess is a sugaring of a common use-case
	# involving EM::popen.
	# Call the #open method on EM::DeferrableChildProcess, passing
	# a command-string. #open immediately returns an EM::Deferrable
	# object. It also schedules the forking of a child process, which
	# will execute the command passed to #open.
	# When the forked child terminates, the Deferrable will be signalled
	# and execute its callbacks, passing the data that the child process
	# wrote to stdout.
	#
	def test_deferrable_child_process
		ls = ""
		EM.run {
			d = EM::DeferrableChildProcess.open( "ls -ltr" )
			d.callback {|data_from_child|
				ls = data_from_child
				EM.stop
			}
		}
		assert( ls.length > 0)
	end

end

