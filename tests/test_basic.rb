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

$:.unshift File.expand_path(File.dirname(__FILE__) + "/../lib")
require 'eventmachine'
require 'socket'
require 'test/unit'

class TestBasic < Test::Unit::TestCase
  def test_connection_class_cache
    mod = Module.new
    a, b = nil, nil
    EM.run {
      EM.start_server '127.0.0.1', 9999, mod
      a = EM.connect '127.0.0.1', 9999, mod
      b = EM.connect '127.0.0.1', 9999, mod
      EM.stop
    }
    assert_equal a.class, b.class
    assert_kind_of EM::Connection, a
  end

  #-------------------------------------


  def test_em
    EventMachine.run {
      EventMachine.add_timer 0 do
        EventMachine.stop
      end
    }
  end

  #-------------------------------------

  def test_timer
    n = 0
    EventMachine.run {
      EventMachine.add_periodic_timer(0.1) {
        n += 1
        EventMachine.stop if n == 2
      }
    }
  end

  #-------------------------------------

  # This test once threw an already-running exception.
  module Trivial
    def post_init
      EventMachine.stop
    end
  end

  def test_server
    EventMachine.run {
      EventMachine.start_server "localhost", 9000, Trivial
      EventMachine.connect "localhost", 9000
    }
    assert( true ) # make sure it halts
  end

  #--------------------------------------

  # EventMachine#run_block starts the reactor loop, runs the supplied block, and then STOPS
  # the loop automatically. Contrast with EventMachine#run, which keeps running the reactor
  # even after the supplied block completes.
  def test_run_block
    assert !EM.reactor_running?
    a = nil
    EM.run_block { a = "Worked" }
    assert a
    assert !EM.reactor_running?
  end

  TestHost = "127.0.0.1"
  TestPort = 9070

  class UnbindError < EM::Connection
    ERR = Class.new(StandardError)
    def initialize *args
      super
    end
    def connection_completed
      close_connection_after_writing
    end
    def unbind
      raise ERR
    end
  end

  def test_unbind_error
    assert_raises( UnbindError::ERR ) {
      EM.run {
        EM.start_server TestHost, TestPort
        EM.connect TestHost, TestPort, UnbindError
      }
    }
  end

  module BrsTestSrv
    def receive_data data
      $received << data
    end
    def unbind
      EM.stop
    end
  end
  module BrsTestCli
    def post_init
      send_data $sent
      close_connection_after_writing
    end
  end

  def setup_timeout(timeout = 4)
    EM.schedule {
      start_time = EM.current_time
      EM.add_periodic_timer(0.01) {
        raise "timeout" if EM.current_time - start_time >= timeout
      }
    }
  end

  # From ticket #50
  def test_byte_range_send
    $received = ''
    $sent = (0..255).to_a.pack('C*')
    EM::run {
      EM::start_server TestHost, TestPort, BrsTestSrv
      EM::connect TestHost, TestPort, BrsTestCli

      setup_timeout
    }
    assert_equal($sent, $received)
  end

  def test_bind_connect
    local_ip = UDPSocket.open {|s| s.connect('google.com', 80); s.addr.last }

    bind_port = rand(33333)+1025

    test = self
    EM.run do
      EM.start_server(TestHost, TestPort, Module.new do
        define_method :post_init do
          begin
            test.assert_equal bind_port, Socket.unpack_sockaddr_in(get_peername).first
            test.assert_equal local_ip, Socket.unpack_sockaddr_in(get_peername).last
          ensure
            EM.stop_event_loop
          end
        end
      end)
      EM.bind_connect local_ip, bind_port, TestHost, TestPort
    end
  end

  def test_reactor_thread?
    assert !EM.reactor_thread?
    EM.run { assert EM.reactor_thread?; EM.stop }
    assert !EM.reactor_thread?
  end

  def test_schedule_on_reactor_thread
    x = false
    EM.run do
      EM.schedule { x = true }
      EM.stop
    end
    assert x
  end
  
  def test_schedule_from_thread
    x = false
    assert !x
    EM.run do
      Thread.new { EM.schedule { x = true; EM.stop } }.join
    end
    assert x
  end

  def test_set_heartbeat_interval
    interval = 0.5
    EM.run {
      EM.set_heartbeat_interval interval
      $interval = EM.get_heartbeat_interval
      EM.stop
    }
    assert_equal(interval, $interval)
  end
  
  module PostInitRaiser
    ERR = Class.new(StandardError)
    def post_init
      raise ERR
    end
  end
  
  def test_bubble_errors_from_post_init
    localhost, port = '127.0.0.1', 9000
    assert_raises(PostInitRaiser::ERR) do
      EM.run do
        EM.start_server localhost, port
        EM.connect localhost, port, PostInitRaiser
      end
    end
  end
  
  module InitializeRaiser
    ERR = Class.new(StandardError)
    def initialize
      raise ERR
    end
  end
  
  def test_bubble_errors_from_initialize
    localhost, port = '127.0.0.1', 9000
    assert_raises(InitializeRaiser::ERR) do
      EM.run do
        EM.start_server localhost, port
        EM.connect localhost, port, InitializeRaiser
      end
    end
  end
end