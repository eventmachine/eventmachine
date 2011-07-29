#--
#
# Author:: Francis Cianfrocca (gmail: blackhedd)
# Homepage::  http://rubyeventmachine.com
# Date:: 25 Aug 2007
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

module EventMachine
  # Support for Erlang-style processes.
  #
  class SpawnedProcess
    # Send a message to the spawned process
    def notify *x
      EM.next_tick {
        # A notification executes in the context of this
        # SpawnedProcess object. That makes self and notify
        # work as one would expect.
        #
        y = call(*x)
        if y and y.respond_to?(:pull_out_yield_block)
          a,b = y.pull_out_yield_block
          set_receiver a
          notify if b
        end
      }
    end
    alias_method :resume, :notify
    alias_method :run, :notify # for formulations like (EM.spawn {xxx}).run

    def set_receiver blk
      class << self; self; end.instance_eval { define_method :call, blk }
    end

  end

  class YieldBlockFromSpawnedProcess # :nodoc:
    def initialize block, notify
      @block = [block,notify]
    end
    def pull_out_yield_block
      @block
    end
  end

  # Spawn an erlang-style process
  def self.spawn &block
    SpawnedProcess.new.tap { |s| s.set_receiver block }
  end

  def self.yield &block # :nodoc:
    YieldBlockFromSpawnedProcess.new( block, false )
  end

  def self.yield_and_notify &block # :nodoc:
    YieldBlockFromSpawnedProcess.new( block, true )
  end
end
