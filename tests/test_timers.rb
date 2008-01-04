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
require 'test/unit'


class TestTimers < Test::Unit::TestCase

  def setup
  end

  def teardown
  end

  def test_timer_with_block
	  x = false
	  EventMachine.run {
		  EventMachine::Timer.new(0.25) {
		  	x = true
			EventMachine.stop
	  	}
	  }
	  assert x
  end

  def test_timer_with_proc
	  x = false
	  EventMachine.run {
		  EventMachine::Timer.new(0.25, proc {
		  	x = true
			EventMachine.stop
	  	})
	  }
	  assert x
  end

  def test_timer_cancel
	  x = true
	  EventMachine.run {
		  timer = EventMachine::Timer.new(0.25, proc { x = false })
		  timer.cancel
		  EventMachine::Timer.new(0.5, proc {EventMachine.stop})
	  }
	  assert x
  end

  def test_periodic_timer
	  x = 0
	  EventMachine.run {
		  EventMachine::PeriodicTimer.new(0.1, proc {
		  	x += 1
			EventMachine.stop if x == 4
		  })
	  }
	  assert( x == 4 )
  end

  def test_periodic_timer_cancel
	  x = 0
	  EventMachine.run {
		pt = EventMachine::PeriodicTimer.new(5, proc { x += 1 })
		pt.cancel
		EventMachine::Timer.new(0.5) {EventMachine.stop}
	  }
	  assert( x == 0 )
  end

  def test_periodic_timer_self_cancel
	  x = 0
	  EventMachine.run {
		pt = EventMachine::PeriodicTimer.new(0.1) {
		  x += 1
		  if x == 4
			  pt.cancel
			  EventMachine.stop
		  end
	  	}
	  }
	  assert( x == 4 )
  end


  	# This test is only applicable to compiled versions of the reactor.
	# Pure ruby versions have no built-in limit on the number of outstanding timers.
	#
	def test_timer_change_max_outstanding
		ten_thousand_timers = proc {
			10000.times {
				EM.add_timer(5) {}
			}
		}
		EM.run {
			if EM.library_type == :pure_ruby
				ten_thousand_timers.call
			else
				assert_raise( RuntimeError ) {
					ten_thousand_timers.call
				}
			end
			EM.stop
		}

		EM.set_max_timers( 10001 )

		EM.run {
			ten_thousand_timers.call
			EM.stop
		}
	end

end

