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

require 'test/unit/testsuite'
require 'test/unit/ui/console/testrunner'


class TestEventables < Test::Unit::TestCase

  class EvTest
    include EventMachine::Eventable
  end

  def setup
  end

  def teardown
  end

  def test_a; end # shut up rake until we define a test.

  # TODO, this idea is still half-baked.
  def xxx_test_a
    n = 0
    tester = EvTest.new
    tester.listen_event( :fire1 ) {|arg|
      n = 1 if arg == "$"
      EventMachine.stop
    }
    tester.post_event( :fire1, "$" )
    
    EventMachine.run {
      EventMachine::add_timer(1) {EventMachine.stop}
    }

    assert_equal( 1, n )
  end

end


#--------------------------------------

if __FILE__ == $0
  runner = Test::Unit::UI::Console::TestRunner
  suite = Test::Unit::TestSuite.new("name")
  ObjectSpace.each_object(Class) do |testcase|
    suite << testcase.suite if testcase < Test::Unit::TestCase
  end
  runner.run(suite)
end

