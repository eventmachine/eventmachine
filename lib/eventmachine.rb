# $Id$
#
# Author:: Francis Cianfrocca (gmail: blackhedd)
# Homepage::  http://rubyeventmachine.com
# Date:: 8 Apr 2006
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


#-- Select in a library based on a global variable.
# PROVISIONALLY commented out this whole mechanism which selects
# a pure-Ruby EM implementation if the extension is not available.
# I expect this will cause a lot of people's code to break, as it
# exposes misconfigurations and path problems that were masked up
# till now. The reason I'm disabling it is because the pure-Ruby
# code will have problems of its own, and it's not nearly as fast
# anyway. Suggested by a problem report from Moshe Litvin. 05Jun07.
#
# 05Dec07: Re-enabled the pure-ruby mechanism, but without the automatic
# fallback feature that tripped up Moshe Litvin. We shouldn't fail over to
# the pure Ruby version because it's possible that the user intended to
# run the extension but failed to do so because of a compilation or
# similar error. So we require either a global variable or an environment
# string be set in order to select the pure-Ruby version.
#

=begin
$eventmachine_library ||= nil
case $eventmachine_library
when :pure_ruby
  require 'pr_eventmachine'
when :extension
  require 'rubyeventmachine'
else
  # This is the case that most user code will take.
  # Prefer the extension if available.
  begin
    require 'rubyeventmachine'
  rescue LoadError
    require 'pr_eventmachine'
  end
end
=end


if RUBY_PLATFORM =~ /java/
	require 'java'
	require 'jeventmachine'
else
	if $eventmachine_library == :pure_ruby or ENV['EVENTMACHINE_LIBRARY'] == "pure_ruby"
		require 'pr_eventmachine'
	else
		require 'rubyeventmachine'
	end
end


require "eventmachine_version"
require 'em/deferrable'
require 'em/future'
require 'em/eventable'
require 'em/messages'
require 'em/streamer'
require 'em/spawnable'

require 'shellwords'

#-- Additional requires are at the BOTTOM of this file, because they
#-- depend on stuff defined in here. Refactor that someday.



# == Introduction
# EventMachine provides a fast, lightweight framework for implementing
# Ruby programs that can use the network to communicate with other
# processes. Using EventMachine, Ruby programmers can easily connect
# to remote servers and act as servers themselves. EventMachine does not
# supplant the Ruby IP libraries. It does provide an alternate technique
# for those applications requiring better performance, scalability,
# and discipline over the behavior of network sockets, than is easily
# obtainable using the built-in libraries, especially in applications
# which are structurally well-suited for the event-driven programming model.
#
# EventMachine provides a perpetual event-loop which your programs can
# start and stop. Within the event loop, TCP network connections are
# initiated and accepted, based on EventMachine methods called by your
# program. You also define callback methods which are called by EventMachine
# when events of interest occur within the event-loop.
#
# User programs will be called back when the following events occur:
# * When the event loop accepts network connections from remote peers
# * When data is received from network connections
# * When connections are closed, either by the local or the remote side
# * When user-defined timers expire
#
# == Usage example
#
# Here's a fully-functional echo server implemented in EventMachine:
# 
#       require 'rubygems'
#       require 'eventmachine'
# 
#       module EchoServer
#         def receive_data data
#           send_data ">>>you sent: #{data}"
#           close_connection if data =~ /quit/i
#         end
#       end
# 
#       EventMachine::run {
#         EventMachine::start_server "192.168.0.100", 8081, EchoServer
#       }
# 
# What's going on here? Well, we have defined the module EchoServer to
# implement the semantics of the echo protocol (more about that shortly).
# The last three lines invoke the event-machine itself, which runs forever
# unless one of your callbacks terminates it. The block that you supply
# to EventMachine::run contains code that runs immediately after the event
# machine is initialized and before it starts looping. This is the place
# to open up a TCP server by specifying the address and port it will listen
# on, together with the module that will process the data.
# 
# Our EchoServer is extremely simple as the echo protocol doesn't require
# much work. Basically you want to send back to the remote peer whatever
# data it sends you. We'll dress it up with a little extra text to make it
# interesting. Also, we'll close the connection in case the received data
# contains the word "quit."
# 
# So what about this module EchoServer? Well, whenever a network connection
# (either a client or a server) starts up, EventMachine instantiates an anonymous
# class, that your module has been mixed into. Exactly one of these class
# instances is created for each connection. Whenever an event occurs on a
# given connection, its corresponding object automatically calls specific
# instance methods which your module may redefine. The code in your module
# always runs in the context of a class instance, so you can create instance
# variables as you wish and they will be carried over to other callbacks
# made on that same connection.
# 
# Looking back up at EchoServer, you can see that we've defined the method
# receive_data which (big surprise) is called whenever data has been received
# from the remote end of the connection. Very simple. We get the data
# (a String object) and can do whatever we wish with it. In this case,
# we use the method send_data to return the received data to the caller,
# with some extra text added in. And if the user sends the word "quit,"
# we'll close the connection with (naturally) close_connection.
# (Notice that closing the connection doesn't terminate the processing loop,
# or change the fact that your echo server is still accepting connections!) 
#
#
# == Questions and Futures
# Would it be useful for EventMachine to incorporate the Observer pattern
# and make use of the corresponding Ruby <tt>observer</tt> package?
# Interesting thought.
#
# 
module EventMachine


	# EventMachine::run initializes and runs an event loop.
	# This method only returns if user-callback code calls stop_event_loop.
	# Use the supplied block to define your clients and servers.
	# The block is called by EventMachine::run immediately after initializing
	# its internal event loop but <i>before</i> running the loop.
	# Therefore this block is the right place to call start_server if you
	# want to accept connections from remote clients.
	#
	# For programs that are structured as servers, it's usually appropriate
	# to start an event loop by calling EventMachine::run, and let it
	# run forever. It's also possible to use EventMachine::run to make a single
	# client-connection to a remote server, process the data flow from that
	# single connection, and then call stop_event_loop to force EventMachine::run
	# to return. Your program will then continue from the point immediately
	# following the call to EventMachine::run.
	#
	# You can of course do both client and servers simultaneously in the same program.
	# One of the strengths of the event-driven programming model is that the
	# handling of network events on many different connections will be interleaved,
	# and scheduled according to the actual events themselves. This maximizes
	# efficiency.
	#
	# === Server usage example
	#
	# See the text at the top of this file for an example of an echo server.
	#
	# === Client usage example
	#
	# See the description of stop_event_loop for an extremely simple client example.
	#
	#--
	# Obsoleted the use_threads mechanism.
	# 25Nov06: Added the begin/ensure block. We need to be sure that release_machine
	# gets called even if an exception gets thrown within any of the user code
	# that the event loop runs. The best way to see this is to run a unit
	# test with two functions, each of which calls EventMachine#run and each of
	# which throws something inside of #run. Without the ensure, the second test
	# will start without release_machine being called and will immediately throw
	# a C++ runtime error.
	#
	def EventMachine::run &block
		@conns = {}
		@acceptors = {}
		@timers = {}
		begin
			@reactor_running = true
			initialize_event_machine
			block and add_timer 0, block
			run_machine
		ensure
			release_machine
			@reactor_running = false
		end
	end


    # Sugars a common use case. Will pass the given block to #run, but will terminate
    # the reactor loop and exit the function as soon as the code in the block completes.
    # (Normally, #run keeps running indefinitely, even after the block supplied to it
    # finishes running, until user code calls #stop.)
    #
    def EventMachine::run_block &block
	    pr = proc {
		    block.call
		    EventMachine::stop
	    }
	    run(&pr)
    end


  # +deprecated+
  #--
  # EventMachine#run_without_threads is semantically identical
  # to EventMachine#run, but it runs somewhat faster.
  # However, it must not be used in applications that spin
  # Ruby threads.
  def EventMachine::run_without_threads &block
    #EventMachine::run false, &block
    EventMachine::run(&block)
  end

  # EventMachine#add_timer adds a one-shot timer to the event loop.
  # Call it with one or two parameters. The first parameters is a delay-time
  # expressed in <i>seconds</i> (not milliseconds). The second parameter, if
  # present, must be a proc object. If a proc object is not given, then you
  # can also simply pass a block to the method call.
  #
  # EventMachine#add_timer may be called from the block passed to EventMachine#run
  # or from any callback method. It schedules execution of the proc or block
  # passed to add_timer, after the passage of an interval of time equal to
  # <i>at least</i> the number of seconds specified in the first parameter to
  # the call.
  #
  # EventMachine#add_timer is a <i>non-blocking</i> call. Callbacks can and will
  # be called during the interval of time that the timer is in effect.
  # There is no built-in limit to the number of timers that can be outstanding at
  # any given time.
  #
  # === Usage example
  #
  # This example shows how easy timers are to use. Observe that two timers are
  # initiated simultaneously. Also, notice that the event loop will continue
  # to run even after the second timer event is processed, since there was
  # no call to EventMachine#stop_event_loop. There will be no activity, of
  # course, since no network clients or servers are defined. Stop the program
  # with Ctrl-C.
  #
  #  require 'rubygems'
  #  require 'eventmachine'
  #
  #  EventMachine::run {
  #    puts "Starting the run now: #{Time.now}"
  #    EventMachine::add_timer 5, proc { puts "Executing timer event: #{Time.now}" }
  #    EventMachine::add_timer( 10 ) { puts "Executing timer event: #{Time.now}" }
  #  }
  #
  #
  #--
  # Changed 04Oct06: We now pass the interval as an integer number of milliseconds.
  #
  def EventMachine::add_timer *args, &block
    interval = args.shift
    code = args.shift || block
    if code
      # check too many timers!
      s = add_oneshot_timer((interval * 1000).to_i)
      @timers[s] = code
      s
    end
  end

  # EventMachine#add_periodic_timer adds a periodic timer to the event loop.
  # It takes the same parameters as the one-shot timer method, EventMachine#add_timer.
  # This method schedules execution of the given block repeatedly, at intervals
  # of time <i>at least</i> as great as the number of seconds given in the first
  # parameter to the call.
  # 
  # === Usage example
  #
  # The following sample program will write a dollar-sign to stderr every five seconds.
  # (Of course if the program defined network clients and/or servers, they would
  # be doing their work while the periodic timer is counting off.)
  #
  #  EventMachine::run {
  #    EventMachine::add_periodic_timer( 5 ) { $stderr.write "$" }
  #  }
  #
  def EventMachine::add_periodic_timer *args, &block
    interval = args.shift
    code = args.shift || block
    if code
      block_1 = proc {
        code.call
        EventMachine::add_periodic_timer interval, code
      }
      add_timer interval, block_1
    end
  end

	#--
	#
	def EventMachine::cancel_timer signature
		@timers[signature] = proc{} if @timers.has_key?(signature)
	end
	private_class_method :cancel_timer


  # stop_event_loop may called from within a callback method
  # while EventMachine's processing loop is running.
  # It causes the processing loop to stop executing, which
  # will cause all open connections and accepting servers
  # to be run down and closed. <i>Callbacks for connection-termination
  # will be called</i> as part of the processing of stop_event_loop.
  # (There currently is no option to panic-stop the loop without
  # closing connections.) When all of this processing is complete,
  # the call to EventMachine::run which started the processing loop
  # will return and program flow will resume from the statement
  # following EventMachine::run call.
  #
  # === Usage example
  #
  #  require 'rubygems'
  #  require 'eventmachine'
  #
  #  module Redmond
  #  
  #    def post_init
  #      puts "We're sending a dumb HTTP request to the remote peer."
  #      send_data "GET / HTTP/1.1\r\nHost: www.microsoft.com\r\n\r\n"
  #    end
  #  
  #    def receive_data data
  #      puts "We received #{data.length} bytes from the remote peer."
  #      puts "We're going to stop the event loop now."
  #      EventMachine::stop_event_loop
  #    end
  #  
  #    def unbind
  #      puts "A connection has terminated."
  #    end
  #  
  #  end
  #  
  #  puts "We're starting the event loop now."
  #  EventMachine::run {
  #    EventMachine::connect "www.microsoft.com", 80, Redmond
  #  }
  #  puts "The event loop has stopped."
  #  
  # This program will produce approximately the following output:
  #
  #  We're starting the event loop now.
  #  We're sending a dumb HTTP request to the remote peer.
  #  We received 1440 bytes from the remote peer.
  #  We're going to stop the event loop now.
  #  A connection has terminated.
  #  The event loop has stopped.
  #
  #
  def EventMachine::stop_event_loop
    EventMachine::stop
  end

  # EventMachine::start_server initiates a TCP server (socket
  # acceptor) on the specified IP address and port.
  # The IP address must be valid on the machine where the program
  # runs, and the process must be privileged enough to listen
  # on the specified port (on Unix-like systems, superuser privileges
  # are usually required to listen on any port lower than 1024).
  # Only one listener may be running on any given address/port
  # combination. start_server will fail if the given address and port
  # are already listening on the machine, either because of a prior call
  # to start_server or some unrelated process running on the machine.
  # If start_server succeeds, the new network listener becomes active
  # immediately and starts accepting connections from remote peers,
  # and these connections generate callback events that are processed
  # by the code specified in the handler parameter to start_server.
  #
  # The optional handler which is passed to start_server is the key
  # to EventMachine's ability to handle particular network protocols.
  # The handler parameter passed to start_server must be a Ruby Module
  # that you must define. When the network server that is started by
  # start_server accepts a new connection, it instantiates a new
  # object of an anonymous class that is inherited from EventMachine::Connection,
  # <i>into which the methods from your handler have been mixed.</i>
  # Your handler module may redefine any of the methods in EventMachine::Connection
  # in order to implement the specific behavior of the network protocol.
  #
  # Callbacks invoked in response to network events <i>always</i> take place
  # within the execution context of the object derived from EventMachine::Connection
  # extended by your handler module. There is one object per connection, and
  # all of the callbacks invoked for a particular connection take the form
  # of instance methods called against the corresponding EventMachine::Connection
  # object. Therefore, you are free to define whatever instance variables you
  # wish, in order to contain the per-connection state required by the network protocol you are
  # implementing.
  #
  # start_server is often called inside the block passed to EventMachine::run,
  # but it can be called from any EventMachine callback. start_server will fail
  # unless the EventMachine event loop is currently running (which is why
  # it's often called in the block suppled to EventMachine::run).
  #
  # You may call start_server any number of times to start up network
  # listeners on different address/port combinations. The servers will
  # all run simultaneously. More interestingly, each individual call to start_server
  # can specify a different handler module and thus implement a different
  # network protocol from all the others.
  #
  # === Usage example
  # Here is an example of a server that counts lines of input from the remote
  # peer and sends back the total number of lines received, after each line.
  # Try the example with more than one client connection opened via telnet,
  # and you will see that the line count increments independently on each
  # of the client connections. Also very important to note, is that the
  # handler for the receive_data function, which our handler redefines, may
  # not assume that the data it receives observes any kind of message boundaries.
  # Also, to use this example, be sure to change the server and port parameters
  # to the start_server call to values appropriate for your environment.
  #
  #  require 'rubygems'
  #  require 'eventmachine'
  #
  #  module LineCounter
  #  
  #    MaxLinesPerConnection = 10
  #  
  #    def post_init
  #      puts "Received a new connection"
  #      @data_received = ""
  #      @line_count = 0
  #    end
  #  
  #    def receive_data data
  #      @data_received << data
  #      while @data_received.slice!( /^[^\n]*[\n]/m )
  #        @line_count += 1
  #        send_data "received #{@line_count} lines so far\r\n"
  #        @line_count == MaxLinesPerConnection and close_connection_after_writing
  #      end
  #    end
  #  
  #  end # module LineCounter
  #  
  #  EventMachine::run {
  #    host,port = "192.168.0.100", 8090
  #    EventMachine::start_server host, port, LineCounter
  #    puts "Now accepting connections on address #{host}, port #{port}..."
  #    EventMachine::add_periodic_timer( 10 ) { $stderr.write "*" }
  #  }
  #  
  #
  def EventMachine::start_server server, port, handler=nil, *args, &block
    klass = if (handler and handler.is_a?(Class))
      handler
    else
      Class.new( Connection ) {handler and include handler}
    end

    arity = klass.instance_method(:initialize).arity
    expected = arity >= 0 ? arity : -(arity + 1)
    if (arity >= 0 and args.size != expected) or (arity < 0 and args.size < expected)
      raise ArgumentError, "wrong number of arguments for #{klass}#initialize (#{args.size} for #{expected})" 
    end

    s = start_tcp_server server, port
    @acceptors[s] = [klass,args,block]
    s
  end


  # Stop a TCP server socket that was started with EventMachine#start_server.
  #--
  # Requested by Kirk Haines. TODO, this isn't OOP enough. We ought somehow
  # to have #start_server return an object that has a close or a stop method on it.
  #
  def EventMachine::stop_server signature
	  EventMachine::stop_tcp_server signature
  end

  def EventMachine::start_unix_domain_server filename, handler=nil, *args, &block
    klass = if (handler and handler.is_a?(Class))
      handler
    else
      Class.new( Connection ) {handler and include handler}
    end

    arity = klass.instance_method(:initialize).arity
    expected = arity >= 0 ? arity : -(arity + 1)
    if (arity >= 0 and args.size != expected) or (arity < 0 and args.size < expected)
      raise ArgumentError, "wrong number of arguments for #{klass}#initialize (#{args.size} for #{expected})" 
    end

    s = start_unix_server filename
    @acceptors[s] = [klass,args,block]
  end

  # EventMachine#connect initiates a TCP connection to a remote
  # server and sets up event-handling for the connection.
  # You can call EventMachine#connect in the block supplied
  # to EventMachine#run or in any callback method.
  #
  # EventMachine#connect takes the IP address (or hostname) and
  # port of the remote server you want to connect to.
  # It also takes an optional handler Module which you must define, that
  # contains the callbacks that will be invoked by the event loop
  # on behalf of the connection.
  #
  # See the description of EventMachine#start_server for a discussion
  # of the handler Module. All of the details given in that description
  # apply for connections created with EventMachine#connect.
  #
  # === Usage Example
  #
  # Here's a program which connects to a web server, sends a naive
  # request, parses the HTTP header of the response, and then
  # (antisocially) ends the event loop, which automatically drops the connection
  # (and incidentally calls the connection's unbind method).
  # 
  #  require 'rubygems'
  #  require 'eventmachine'
  #  
  #  module DumbHttpClient
  #  
  #    def post_init
  #      send_data "GET / HTTP/1.1\r\nHost: _\r\n\r\n"
  #      @data = ""
  #    end
  #  
  #    def receive_data data
  #      @data << data
  #      if  @data =~ /[\n][\r]*[\n]/m
  #        puts "RECEIVED HTTP HEADER:"
  #        $`.each {|line| puts ">>> #{line}" }
  #  
  #        puts "Now we'll terminate the loop, which will also close the connection"
  #        EventMachine::stop_event_loop
  #      end
  #    end
  #  
  #    def unbind
  #      puts "A connection has terminated"
  #    end
  #  
  #  end # DumbHttpClient
  #  
  #  
  #  EventMachine::run {
  #    EventMachine::connect "www.bayshorenetworks.com", 80, DumbHttpClient
  #  }
  #  puts "The event loop has ended"
  #  
  #
  # There are times when it's more convenient to define a protocol handler
  # as a Class rather than a Module. Here's how to do this:
  #
  #  class MyProtocolHandler < EventMachine::Connection
  #    def initialize *args
  #      super
  #      # whatever else you want to do here
  #    end
  #    
  #    #.......your other class code
  #  end # class MyProtocolHandler
  #
  # If you do this, then an instance of your class will be instantiated to handle
  # every network connection created by your code or accepted by servers that you
  # create. If you redefine #post_init in your protocol-handler class, your
  # #post_init method will be called _inside_ the call to #super that you will
  # make in your #initialize method (if you provide one).
  #
  #--
  # EventMachine::connect initiates a TCP connection to a remote
  # server and sets up event-handling for the connection.
  # It internally creates an object that should not be handled
  # by the caller. HOWEVER, it's often convenient to get the
  # object to set up interfacing to other objects in the system.
  # We return the newly-created anonymous-class object to the caller.
  # It's expected that a considerable amount of code will depend
  # on this behavior, so don't change it.
  #
  # Ok, added support for a user-defined block, 13Apr06.
  # This leads us to an interesting choice because of the
  # presence of the post_init call, which happens in the
  # initialize method of the new object. We call the user's
  # block and pass the new object to it. This is a great
  # way to do protocol-specific initiation. It happens
  # AFTER post_init has been called on the object, which I
  # certainly hope is the right choice.
  # Don't change this lightly, because accepted connections
  # are different from connected ones and we don't want
  # to have them behave differently with respect to post_init
  # if at all possible.
  #
  def EventMachine::connect server, port, handler=nil, *args
    klass = if (handler and handler.is_a?(Class))
      handler
    else
      Class.new( Connection ) {handler and include handler}
    end

    arity = klass.instance_method(:initialize).arity
    expected = arity >= 0 ? arity : -(arity + 1)
    if (arity >= 0 and args.size != expected) or (arity < 0 and args.size < expected)
      raise ArgumentError, "wrong number of arguments for #{klass}#initialize (#{args.size} for #{expected})"
    end

    s = connect_server server, port
    c = klass.new s, *args
    @conns[s] = c
    block_given? and yield c
    c
  end


    #--
    # EXPERIMENTAL. DO NOT RELY ON THIS METHOD TO BE HERE IN THIS FORM, OR AT ALL.
    # (03Nov06)
    # Observe, the test for already-connected FAILS if we call a reconnect inside post_init,
    # because we haven't set up the connection in @conns by that point.
    # RESIST THE TEMPTATION to "fix" this problem by redefining the behavior of post_init.
    #
    # Changed 22Nov06: if called on an already-connected handler, just return the
    # handler and do nothing more. Originally this condition raised an exception.
    # We may want to change it yet again and call the block, if any.
    #
    def EventMachine::reconnect server, port, handler
	raise "invalid handler" unless handler.respond_to?(:connection_completed)
	#raise "still connected" if @conns.has_key?(handler.signature)
	return handler if @conns.has_key?(handler.signature)
	s = connect_server server, port
	handler.signature = s
	@conns[s] = handler
	block_given? and yield handler
	handler
    end




	# Make a connection to a Unix-domain socket. This is not implemented on Windows platforms.
	# The parameter socketname is a String which identifies the Unix-domain socket you want
	# to connect to. socketname is the name of a file on your local system, and in most cases
	# is a fully-qualified path name. Make sure that your process has enough local permissions
	# to open the Unix-domain socket.
	# See also the documentation for #connect_server. This method behaves like #connect_server
	# in all respects except for the fact that it connects to a local Unix-domain
	# socket rather than a TCP socket.
	# NOTE: this functionality will soon be subsumed into the #connect method. This method
	# will still be supported as an alias.
	#--
	# For making connections to Unix-domain sockets.
	# Eventually this has to get properly documented and unified with the TCP-connect methods.
	# Note how nearly identical this is to EventMachine#connect
	def EventMachine::connect_unix_domain socketname, handler=nil, *args
		klass = if (handler and handler.is_a?(Class))
			handler
		else
			Class.new( Connection ) {handler and include handler}
		end

    arity = klass.instance_method(:initialize).arity
    expected = arity >= 0 ? arity : -(arity + 1)
    if (arity >= 0 and args.size != expected) or (arity < 0 and args.size < expected)
      raise ArgumentError, "wrong number of arguments for #{klass}#initialize (#{args.size} for #{expected})"
    end

		s = connect_unix_server socketname
		c = klass.new s, *args
		@conns[s] = c
		block_given? and yield c
		c
	end


	# EventMachine#open_datagram_socket is for support of UDP-based
	# protocols. Its usage is similar to that of EventMachine#start_server.
	# It takes three parameters: an IP address (which must be valid
	# on the machine which executes the method), a port number,
	# and an optional Module name which will handle the data.
	# This method will create a new UDP (datagram) socket and
	# bind it to the address and port that you specify.
	# The normal callbacks (see EventMachine#start_server) will
	# be called as events of interest occur on the newly-created
	# socket, but there are some differences in how they behave.
	#
	# Connection#receive_data will be called when a datagram packet
	# is received on the socket, but unlike TCP sockets, the message
	# boundaries of the received data will be respected. In other words,
	# if the remote peer sent you a datagram of a particular size,
	# you may rely on Connection#receive_data to give you the
	# exact data in the packet, with the original data length.
	# Also observe that Connection#receive_data may be called with a
	# <i>zero-length</i> data payload, since empty datagrams are permitted
	# in UDP.
	#
	# Connection#send_data is available with UDP packets as with TCP,
	# but there is an important difference. Because UDP communications
	# are <i>connectionless,</i> there is no implicit recipient for the packets you
	# send. Ordinarily you must specify the recipient for each packet you send.
	# However, EventMachine
	# provides for the typical pattern of receiving a UDP datagram
	# from a remote peer, performing some operation, and then sending
	# one or more packets in response to the same remote peer.
	# To support this model easily, just use Connection#send_data
	# in the code that you supply for Connection:receive_data.
	# EventMachine will
	# provide an implicit return address for any messages sent to
	# Connection#send_data within the context of a Connection#receive_data callback,
	# and your response will automatically go to the correct remote peer.
	# (TODO: Example-code needed!)
	#
	# Observe that the port number that you supply to EventMachine#open_datagram_socket
	# may be zero. In this case, EventMachine will create a UDP socket
	# that is bound to an <i>ephemeral</i> (not well-known) port.
	# This is not appropriate for servers that must publish a well-known
	# port to which remote peers may send datagrams. But it can be useful
	# for clients that send datagrams to other servers.
	# If you do this, you will receive any responses from the remote
	# servers through the normal Connection#receive_data callback.
	# Observe that you will probably have issues with firewalls blocking
	# the ephemeral port numbers, so this technique is most appropriate for LANs.
	# (TODO: Need an example!)
	#
	# If you wish to send datagrams to arbitrary remote peers (not
	# necessarily ones that have sent data to which you are responding),
	# then see Connection#send_datagram.
	#
	# DO NOT call send_data from a datagram socket
	# outside of a #receive_data method. Use #send_datagram. If you do use #send_data
	# outside of a #receive_data method, you'll get a confusing error
	# because there is no "peer," as #send_data requires. (Inside of #receive_data,
	# #send_data "fakes" the peer as described above.)
	#
	#--
	# Replaced the implementation on 01Oct06. Thanks to Tobias Gustafsson for pointing
	# out that this originally did not take a class but only a module.
	#
	def self::open_datagram_socket address, port, handler=nil, *args
		klass = if (handler and handler.is_a?(Class))
			handler
		else
			Class.new( Connection ) {handler and include handler}
		end

    arity = klass.instance_method(:initialize).arity
    expected = arity >= 0 ? arity : -(arity + 1)
    if (arity >= 0 and args.size != expected) or (arity < 0 and args.size < expected)
      raise ArgumentError, "wrong number of arguments for #{klass}#initialize (#{args.size} for #{expected})"
    end

		s = open_udp_socket address, port
		c = klass.new s, *args
		@conns[s] = c
		block_given? and yield c
		c
	end


	# For advanced users. This function sets the default timer granularity, which by default is
	# slightly smaller than 100 milliseconds. Call this function to set a higher or lower granularity.
	# The function affects the behavior of #add_timer and #add_periodic_timer. Most applications
	# will not need to call this function.
	#
	# The argument is a number of milliseconds. Avoid setting the quantum to very low values because
	# that may reduce performance under some extreme conditions. We recommend that you not set a quantum
	# lower than 10.
	#
	# You may only call this function while an EventMachine loop is running (that is, after a call to
	# EventMachine#run and before a subsequent call to EventMachine#stop).
	#
	def self::set_quantum mills
		set_timer_quantum mills.to_i
	end

	# Sets the maximum number of timers and periodic timers that may be outstanding at any
	# given time. You only need to call #set_max_timers if you need more than the default
	# number of timers, which on most platforms is 1000.
	# Call this method before calling EventMachine#run.
	#
	def self::set_max_timers ct
		set_max_timer_count ct
	end

	#--
	# The is the responder for the loopback-signalled event.
	# It can be fired either by code running on a separate thread (EM#defer) or on
	# the main thread (EM#next_tick).
	# It will often happen that a next_tick handler will reschedule itself. We
	# consume a copy of the tick queue so that tick events scheduled by tick events
	# have to wait for the next pass through the reactor core.
	#
	def self::run_deferred_callbacks # :nodoc:
		until (@resultqueue ||= []).empty?
			result,cback = @resultqueue.pop
			cback.call result if cback
		end

		@next_tick_queue ||= []
		if (l = @next_tick_queue.length) > 0
			l.times {|i| @next_tick_queue[i].call}
			@next_tick_queue.slice!( 0...l )
		end

=begin
		(@next_tick_queue ||= []).length.times {
			cback=@next_tick_queue.pop and cback.call
		}
=end
=begin
		if (@next_tick_queue ||= []) and @next_tick_queue.length > 0
			ary = @next_tick_queue.dup
			@next_tick_queue.clear
			until ary.empty?
				cback=ary.pop and cback.call
			end
		end
=end
	end


	# #defer is for integrating blocking operations into EventMachine's control flow.
	# Call #defer with one or two blocks, as shown below (the second block is <i>optional</i>):
	#  
	#  operation = proc {
	#    # perform a long-running operation here, such as a database query.
	#    "result" # as usual, the last expression evaluated in the block will be the return value.
	#  }
	#  callback = proc {|result|
	#    # do something with result here, such as send it back to a network client.
	#  }
	#
	#  EventMachine.defer( operation, callback )
	#  
	# The action of #defer is to take the block specified in the first parameter (the "operation")
	# and schedule it for asynchronous execution on an internal thread pool maintained by EventMachine.
	# When the operation completes, it will pass the result computed by the block (if any)
	# back to the EventMachine reactor. Then, EventMachine calls the block specified in the
	# second parameter to #defer (the "callback"), as part of its normal, synchronous
	# event handling loop. The result computed by the operation block is passed as a parameter
	# to the callback. You may omit the callback parameter if you don't need to execute any code
	# after the operation completes.
	#
	# <i>Caveats:</i>
	# Note carefully that the code in your deferred operation will be executed on a separate
	# thread from the main EventMachine processing and all other Ruby threads that may exist in
	# your program. Also, multiple deferred operations may be running at once! Therefore, you
	# are responsible for ensuring that your operation code is threadsafe. [Need more explanation
	# and examples.]
	# Don't write a deferred operation that will block forever. If so, the current implementation will
	# not detect the problem, and the thread will never be returned to the pool. EventMachine limits
	# the number of threads in its pool, so if you do this enough times, your subsequent deferred
	# operations won't get a chance to run. [We might put in a timer to detect this problem.]
	#
	#--
	# OBSERVE that #next_tick hacks into this mechanism, so don't make any changes here
	# without syncing there.
	#
	# Running with $VERBOSE set to true gives a warning unless all ivars are defined when
	# they appear in rvalues. But we DON'T ever want to initialize @threadqueue unless we
	# need it, because the Ruby threads are so heavyweight. We end up with this bizarre
	# way of initializing @threadqueue because EventMachine is a Module, not a Class, and
	# has no constructor.
	#
	def self::defer op, callback = nil
		@need_threadqueue ||= 0
		if @need_threadqueue == 0
			@need_threadqueue = 1
			require 'thread'
			@threadqueue = Queue.new
			@resultqueue = Queue.new
			20.times {|ix|
				Thread.new {
					my_ix = ix
					loop {
						op,cback = @threadqueue.pop
						result = op.call
						@resultqueue << [result, cback]
						EventMachine.signal_loopbreak
					}
				}
			}
		end

		@threadqueue << [op,callback]
	end


  	# Schedules a proc for execution immediately after the next "turn" through the reactor
	# core. An advanced technique, this can be useful for improving memory management and/or
	# application responsiveness, especially when scheduling large amounts of data for
	# writing to a network connection. TODO, we need a FAQ entry on this subject.
	#
	# #next_tick takes either a single argument (which must be a Proc) or a block.
	# And I'm taking suggestions for a better name for this method.
	#--
	# This works by adding to the @resultqueue that's used for #defer.
	# The general idea is that next_tick is used when we want to give the reactor a chance
	# to let other operations run, either to balance the load out more evenly, or to let
	# outbound network buffers drain, or both. So we probably do NOT want to block, and
	# we probably do NOT want to be spinning any threads. A program that uses next_tick
	# but not #defer shouldn't suffer the penalty of having Ruby threads running. They're
	# extremely expensive even if they're just sleeping.
	#
	def self::next_tick pr=nil, &block
		raise "no argument or block given" unless ((pr && pr.respond_to?(:call)) or block)
		(@next_tick_queue ||= []) << ( pr || block )
		EventMachine.signal_loopbreak
=begin
		(@next_tick_procs ||= []) << (pr || block)
		if @next_tick_procs.length == 1
			add_timer(0) {
				@next_tick_procs.each {|t| t.call}
				@next_tick_procs.clear
			}
		end
=end
	end

	# A wrapper over the setuid system call. Particularly useful when opening a network
	# server on a privileged port because you can use this call to drop privileges
	# after opening the port. Also very useful after a call to #set_descriptor_table_size,
	# which generally requires that you start your process with root privileges.
	#
	# This method has no effective implementation on Windows or in the pure-Ruby
	# implementation of EventMachine.
	# Call #set_effective_user by passing it a string containing the effective name
	# of the user whose privilege-level your process should attain.
	# This method is intended for use in enforcing security requirements, consequently
	# it will throw a fatal error and end your program if it fails.
	#
	def self::set_effective_user username
		EventMachine::setuid_string username
	end


	# Sets the maximum number of file or socket descriptors that your process may open.
	# You can pass this method an integer specifying the new size of the descriptor table.
	# Returns the new descriptor-table size, which may be less than the number you
	# requested. If you call this method with no arguments, it will simply return
	# the current size of the descriptor table without attempting to change it.
	#
	# The new limit on open descriptors ONLY applies to sockets and other descriptors
	# that belong to EventMachine. It has NO EFFECT on the number of descriptors
	# you can create in ordinary Ruby code.
	#
	# Not available on all platforms. Increasing the number of descriptors beyond its
	# default limit usually requires superuser privileges. (See #set_effective_user
	# for a way to drop superuser privileges while your program is running.)
	#
	def self::set_descriptor_table_size n_descriptors=nil
		EventMachine::set_rlimit_nofile n_descriptors
	end



	# TODO, must document popen. At this moment, it's only available on Unix.
	# This limitation is expected to go away.
	#--
	# Perhaps misnamed since the underlying function uses socketpair and is full-duplex.
	#
	def self::popen cmd, handler=nil
		klass = if (handler and handler.is_a?(Class))
			handler
		else
			Class.new( Connection ) {handler and include handler}
		end

		w = Shellwords::shellwords( cmd )
		w.unshift( w.first ) if w.first
		s = invoke_popen( w )
		c = klass.new s
		@conns[s] = c
		yield(c) if block_given?
		c
	end


	# Tells you whether the EventMachine reactor loop is currently running. Returns true or
	# false. Useful when writing libraries that want to run event-driven code, but may
	# be running in programs that are already event-driven. In such cases, if EventMachine#reactor_running?
	# returns false, your code can invoke EventMachine#run and run your application code inside
	# the block passed to that method. If EventMachine#reactor_running? returns true, just
	# execute your event-aware code.
	#
	# This method is necessary because calling EventMachine#run inside of another call to
	# EventMachine#run generates a fatal error.
	#
	def self::reactor_running?
		(@reactor_running || false)
	end


	# (Experimental)
	#
	#
	def EventMachine::open_keyboard handler=nil
		klass = if (handler and handler.is_a?(Class))
			handler
		else
			Class.new( Connection ) {handler and include handler}
		end

		s = read_keyboard
		c = klass.new s
		@conns[s] = c
		block_given? and yield c
		c
	end



	private
	def EventMachine::event_callback conn_binding, opcode, data
		#
		# Changed 27Dec07: Eliminated the hookable error handling.
		# No one was using it, and it degraded performance significantly.
		# It's in original_event_callback, which is dead code.
		#
		if opcode == ConnectionData
			c = @conns[conn_binding] or raise ConnectionNotBound
			c.receive_data data
		elsif opcode == ConnectionUnbound
			if c = @conns.delete( conn_binding )
				c.unbind
			elsif c = @acceptors.delete( conn_binding )
				# no-op
			else
				raise ConnectionNotBound
			end
		elsif opcode == ConnectionAccepted
			accep,args,blk = @acceptors[conn_binding]
			raise NoHandlerForAcceptedConnection unless accep
			c = accep.new data, *args
			@conns[data] = c
			blk and blk.call(c)
			c # (needed?)
		elsif opcode == TimerFired
			t = @timers.delete( data ) or raise UnknownTimerFired
			t.call
		elsif opcode == ConnectionCompleted
			c = @conns[conn_binding] or raise ConnectionNotBound
			c.connection_completed
		elsif opcode == LoopbreakSignalled
			run_deferred_callbacks
		end
	end

	private
	def EventMachine::original_event_callback conn_binding, opcode, data
		#
		# Added 03Oct07: Any code path that invokes user-written code must
		# wrap itself in a begin/rescue for RuntimeErrors, that calls the
		# user-overridable class method #handle_runtime_error.
		#
		if opcode == ConnectionData
			c = @conns[conn_binding] or raise ConnectionNotBound
			begin
				c.receive_data data
			rescue
				EventMachine.handle_runtime_error
			end
		elsif opcode == ConnectionUnbound
			if c = @conns.delete( conn_binding )
				begin
					c.unbind
				rescue
					EventMachine.handle_runtime_error
				end
			elsif c = @acceptors.delete( conn_binding )
				# no-op
			else
				raise ConnectionNotBound
			end
		elsif opcode == ConnectionAccepted
			accep,args,blk = @acceptors[conn_binding]
			raise NoHandlerForAcceptedConnection unless accep
			c = accep.new data, *args
			@conns[data] = c
			begin
				blk and blk.call(c)
			rescue
				EventMachine.handle_runtime_error
			end
			c # (needed?)
		elsif opcode == TimerFired
			t = @timers.delete( data ) or raise UnknownTimerFired
			begin
				t.call
			rescue
				EventMachine.handle_runtime_error
			end
		elsif opcode == ConnectionCompleted
			c = @conns[conn_binding] or raise ConnectionNotBound
			begin
				c.connection_completed
			rescue
				EventMachine.handle_runtime_error
			end
		elsif opcode == LoopbreakSignalled
			begin
			run_deferred_callbacks
			rescue
				EventMachine.handle_runtime_error
			end
		end
	end


	# Default handler for RuntimeErrors that are raised in user code.
	# The default behavior is to re-raise the error, which ends your program.
	# To override the default behavior, re-implement this method in your code.
	# For example:
	#
	#  module EventMachine
	#    def self.handle_runtime_error
	#      $>.puts $!
	#    end
	#  end
	#
	#--
	# We need to ensure that any code path which invokes user code rescues RuntimeError
	# and calls this method. The obvious place to do that is in #event_callback,
	# but, scurrilously, it turns out that we need to be finer grained that that.
	# Periodic timers, in particular, wrap their invocations of user code inside
	# procs that do other stuff we can't not do, like schedule the next invocation.
	# This is a potential non-robustness, since we need to remember to hook in the
	# error handler whenever and wherever we change how user code is invoked.
	#
	def EventMachine::handle_runtime_error
		@runtime_error_hook ? @runtime_error_hook.call : raise
	end

	# Sets a handler for RuntimeErrors that are raised in user code.
	# Pass a block with no parameters. You can also call this method without a block,
	# which restores the default behavior (see #handle_runtime_error).
	#
	def EventMachine::set_runtime_error_hook &blk
		@runtime_error_hook = blk
	end

  # Documentation stub
  #--
  # This is a provisional implementation of a stream-oriented file access object.
  # We also experiment with wrapping up some better exception reporting.
  class << self
    def _open_file_for_writing filename, handler=nil
      klass = if (handler and handler.is_a?(Class))
        handler
      else
        Class.new( Connection ) {handler and include handler}
      end

      s = _write_file filename
      c = klass.new s
      @conns[s] = c
      block_given? and yield c
      c
    end
  end


# EventMachine::Connection is a class that is instantiated
# by EventMachine's processing loop whenever a new connection
# is created. (New connections can be either initiated locally
# to a remote server or accepted locally from a remote client.)
# When a Connection object is instantiated, it <i>mixes in</i>
# the functionality contained in the user-defined module
# specified in calls to EventMachine#connect or EventMachine#start_server.
# User-defined handler modules may redefine any or all of the standard
# methods defined here, as well as add arbitrary additional code
# that will also be mixed in.
#
# EventMachine manages one object inherited from EventMachine::Connection
# (and containing the mixed-in user code) for every network connection
# that is active at any given time.
# The event loop will automatically call methods on EventMachine::Connection
# objects whenever specific events occur on the corresponding connections,
# as described below.
#
# This class is never instantiated by user code, and does not publish an
# initialize method. The instance methods of EventMachine::Connection
# which may be called by the event loop are: post_init, receive_data,
# and unbind. All of the other instance methods defined here are called
# only by user code.
#
class Connection
	# EXPERIMENTAL. Added the reconnect methods, which may go away.
	attr_accessor :signature

  # Override .new so subclasses don't have to call super and can ignore
  # connection-specific arguments
  #
  def self.new sig, *args #:nodoc:
    allocate.instance_eval do
      # Call a superclass's #initialize if it has one
      initialize *args

      # Store signature and run #post_init
      @signature = sig
      associate_callback_target sig
      post_init
    
      self
    end
  end

  # Stubbed initialize so legacy superclasses can safely call super
  #
	def initialize(*args) #:nodoc:
  end

	# EventMachine::Connection#post_init is called by the event loop
	# immediately after the network connection has been established,
	# and before resumption of the network loop.
	# This method is generally not called by user code, but is called automatically
	# by the event loop. The base-class implementation is a no-op.
	# This is a very good place to initialize instance variables that will
	# be used throughout the lifetime of the network connection.
	#
	def post_init
	end

	# EventMachine::Connection#receive_data is called by the event loop
	# whenever data has been received by the network connection.
	# It is never called by user code.
	# receive_data is called with a single parameter, a String containing
	# the network protocol data, which may of course be binary. You will
	# generally redefine this method to perform your own processing of the incoming data.
	#
	# Here's a key point which is essential to understanding the event-driven
	# programming model: <i>EventMachine knows absolutely nothing about the protocol
	# which your code implements.</i> You must not make any assumptions about
	# the size of the incoming data packets, or about their alignment on any
	# particular intra-message or PDU boundaries (such as line breaks).
	# receive_data can and will send you arbitrary chunks of data, with the
	# only guarantee being that the data is presented to your code in the order
	# it was collected from the network. Don't even assume that the chunks of
	# data will correspond to network packets, as EventMachine can and will coalesce
	# several incoming packets into one, to improve performance. The implication for your
	# code is that you generally will need to implement some kind of a state machine
	# in your redefined implementation of receive_data. For a better understanding
	# of this, read through the examples of specific protocol handlers given
	# elsewhere in this package. (STUB, WE MUST ADD THESE!)
	#
	# The base-class implementation of receive_data (which will be invoked if
	# you don't redefine it) simply prints the size of each incoming data packet
	# to stdout.
	#
	def receive_data data
		puts "............>>>#{data.length}"
	end

	# EventMachine::Connection#unbind is called by the framework whenever a connection
	# (either a server or client connection) is closed. The close can occur because
	# your code intentionally closes it (see close_connection and close_connection_after_writing),
	# because the remote peer closed the connection, or because of a network error.
	# You may not assume that the network connection is still open and able to send or
	# receive data when the callback to unbind is made. This is intended only to give
	# you a chance to clean up associations your code may have made to the connection
	# object while it was open.
	#
	def unbind
	end

	# EventMachine::Connection#close_connection is called only by user code, and never
	# by the event loop. You may call this method against a connection object in any
	# callback handler, whether or not the callback was made against the connection
	# you want to close. close_connection <i>schedules</i> the connection to be closed
	# at the next available opportunity within the event loop. You may not assume that
	# the connection is closed when close_connection returns. In particular, the framework
	# will callback the unbind method for the particular connection at a point shortly
	# after you call close_connection. You may assume that the unbind callback will
	# take place sometime after your call to close_connection completes. In other words,
	# the unbind callback will not re-enter your code "inside" of your call to close_connection.
	# However, it's not guaranteed that a future version of EventMachine will not change
	# this behavior.
	#
	# close_connection will <i>silently discard</i> any outbound data which you have
	# sent to the connection using EventMachine::Connection#send_data but which has not
	# yet been sent across the network. If you want to avoid this behavior, use
	# EventMachine::Connection#close_connection_after_writing.
	#
	def close_connection after_writing = false
		EventMachine::close_connection @signature, after_writing
	end

	# EventMachine::Connection#close_connection_after_writing is a variant of close_connection.
	# All of the descriptive comments given for close_connection also apply to
	# close_connection_after_writing, <i>with one exception:</i> If the connection has
	# outbound data sent using send_dat but which has not yet been sent across the network,
	# close_connection_after_writing will schedule the connection to be closed <i>after</i>
	# all of the outbound data has been safely written to the remote peer.
	#
	# Depending on the amount of outgoing data and the speed of the network,
	# considerable time may elapse between your call to close_connection_after_writing
	# and the actual closing of the socket (at which time the unbind callback will be called
	# by the event loop). During this time, you <i>may not</i> call send_data to transmit
	# additional data (that is, the connection is closed for further writes). In very
	# rare cases, you may experience a receive_data callback after your call to close_connection_after_writing,
	# depending on whether incoming data was in the process of being received on the connection
	# at the moment when you called close_connection_after_writing. Your protocol handler must
	# be prepared to properly deal with such data (probably by ignoring it).
	#
	def close_connection_after_writing
		close_connection true
	end

	# EventMachine::Connection#send_data is only called by user code, never by
	# the event loop. You call this method to send data to the remote end of the
	# network connection. send_data is called with a single String argument, which
	# may of course contain binary data. You can call send_data any number of times.
	# send_data is an instance method of an object derived from EventMachine::Connection
	# and containing your mixed-in handler code), so if you call it without qualification
	# within a callback function, the data will be sent to the same network connection
	# that generated the callback. Calling self.send_data is exactly equivalent.
	#
	# You can also call send_data to write to a connection <i>other than the one
	# whose callback you are calling send_data from.</i> This is done by recording
	# the value of the connection in any callback function (the value self), in any
	# variable visible to other callback invocations on the same or different
	# connection objects. (Need an example to make that clear.)
	#
	def send_data data
		EventMachine::send_data @signature, data, data.length
	end

	# Returns true if the connection is in an error state, false otherwise.
	# In general, you can detect the occurrence of communication errors or unexpected
	# disconnection by the remote peer by handing the #unbind method. In some cases, however,
	# it's useful to check the status of the connection using #error? before attempting to send data.
	# This function is synchronous: it will return immediately without blocking.
	#
	#
	def error?
		EventMachine::report_connection_error_status(@signature) != 0
	end

	# #connection_completed is called by the event loop when a remote TCP connection
	# attempt completes successfully. You can expect to get this notification after calls
	# to EventMachine#connect. Remember that EventMachine makes remote connections
	# asynchronously, just as with any other kind of network event. #connection_completed
	# is intended primarily to assist with network diagnostics. For normal protocol
	# handling, use #post_init to perform initial work on a new connection (such as
	# send an initial set of data).
	# #post_init will always be called. #connection_completed will only be called in case
	# of a successful completion. A connection-attempt which fails will receive a call
	# to #unbind after the failure.
	def connection_completed
	end

	# Call #start_tls at any point to initiate TLS encryption on connected streams.
	# The method is smart enough to know whether it should perform a server-side
	# or a client-side handshake. An appropriate place to call #start_tls is in
	# your redefined #post_init method, or in the #connection_completed handler for
	# an outbound connection.
	#
	# #start_tls takes an optional parameter hash that allows you to specify certificate
	# and other options to be used with this Connection object. Here are the currently-supported
	# options:
	# :cert_chain_file : takes a String, which is interpreted as the name of a readable file in the
	#   local filesystem. The file is expected to contain a chain of X509 certificates in
	#   PEM format, with the most-resolved certificate at the top of the file, successive
	#   intermediate certs in the middle, and the root (or CA) cert at the bottom.
	#
	# :private_key_file : tales a String, which is interpreted as the name of a readable file in the
	#   local filesystem. The file must contain a private key in PEM format.
	#
	#--
	# TODO: support passing an encryption parameter, which can be string or Proc, to get a passphrase
	# for encrypted private keys.
	# TODO: support passing key material via raw strings or Procs that return strings instead of
	# just filenames.
	# What will get nasty is whether we have to define a location for storing this stuff as files.
	# In general, the OpenSSL interfaces for dealing with certs and keys in files are much better
	# behaved than the ones for raw chunks of memory.
	#
	def start_tls args={}
		EventMachine::set_tls_parms(
			@signature,
			args[:private_key_file] || "",
			args[:cert_chain_file] || ""
		)
		EventMachine::start_tls @signature
	end


	# send_datagram is for sending UDP messages.
	# This method may be called from any Connection object that refers
	# to an open datagram socket (see EventMachine#open_datagram_socket).
	# The method sends a UDP (datagram) packet containing the data you specify,
	# to a remote peer specified by the IP address and port that you give
	# as parameters to the method.
	# Observe that you may send a zero-length packet (empty string).
	# However, you may not send an arbitrarily-large data packet because
	# your operating system will enforce a platform-specific limit on
	# the size of the outbound packet. (Your kernel
	# will respond in a platform-specific way if you send an overlarge
	# packet: some will send a truncated packet, some will complain, and
	# some will silently drop your request).
	# On LANs, it's usually OK to send datagrams up to about 4000 bytes in length,
	# but to be really safe, send messages smaller than the Ethernet-packet
	# size (typically about 1400 bytes). Some very restrictive WANs
	# will either drop or truncate packets larger than about 500 bytes.
	#--
	# Added the Integer wrapper around the port parameter per suggestion by
	# Matthieu Riou, after he passed a String and spent hours tearing his hair out.
	#
	def send_datagram data, recipient_address, recipient_port
		data = data.to_s
		EventMachine::send_datagram @signature, data, data.length, recipient_address, Integer(recipient_port)
	end


	# #get_peername is used with stream-connections to obtain the identity
	# of the remotely-connected peer. If a peername is available, this method
	# returns a sockaddr structure. The method returns nil if no peername is available.
	# You can use Socket#unpack_sockaddr_in and its variants to obtain the
	# values contained in the peername structure returned from #get_peername.
	def get_peername
		EventMachine::get_peername @signature
	end

	# #get_sockname is used with stream-connections to obtain the identity
	# of the local side of the connection. If a local name is available, this method
	# returns a sockaddr structure. The method returns nil if no local name is available.
	# You can use Socket#unpack_sockaddr_in and its variants to obtain the
	# values contained in the local-name structure returned from #get_sockname.
	def get_sockname
		EventMachine::get_sockname @signature
	end

	# Returns the PID (kernel process identifier) of a subprocess
	# associated with this Connection object. For use with EventMachine#popen
	# and similar methods. Returns nil when there is no meaningful subprocess.
	#--
	#
	def get_pid
		EventMachine::get_subprocess_pid @signature
	end

	# Returns a subprocess exit status. Only useful for #popen. Call it in your
	# #unbind handler.
	#
	def get_status
		EventMachine::get_subprocess_status @signature
	end

	# comm_inactivity_timeout returns the current value (in seconds) of the inactivity-timeout
	# property of network-connection and datagram-socket objects. A nonzero value
	# indicates that the connection or socket will automatically be closed if no read or write
	# activity takes place for at least that number of seconds.
	# A zero value (the default) specifies that no automatic timeout will take place.
	def comm_inactivity_timeout
		EventMachine::get_comm_inactivity_timeout @signature
	end

	# Alias for #set_comm_inactivity_timeout.
	def comm_inactivity_timeout= value
		self.send :set_comm_inactivity_timeout, value
	end

	# comm_inactivity_timeout= allows you to set the inactivity-timeout property for
	# a network connection or datagram socket. Specify a non-negative numeric value in seconds.
	# If the value is greater than zero, the connection or socket will automatically be closed
	# if no read or write activity takes place for at least that number of seconds.
	# Specify a value of zero to indicate that no automatic timeout should take place.
	# Zero is the default value.
	def set_comm_inactivity_timeout value
		EventMachine::set_comm_inactivity_timeout @signature, value
	end

	#--
	# EXPERIMENTAL. DO NOT RELY ON THIS METHOD TO REMAIN SUPPORTED.
	# (03Nov06)
	def reconnect server, port
		EventMachine::reconnect server, port, self
	end


	# Like EventMachine::Connection#send_data, this sends data to the remote end of
	# the network connection.  EventMachine::Connection@send_file_data takes a
	# filename as an argument, though, and sends the contents of the file, in one
	# chunk. Contributed by Kirk Haines.
	#
	def send_file_data filename
		EventMachine::send_file_data @signature, filename
	end

	# Open a file on the filesystem and send it to the remote peer. This returns an
	# object of type EventMachine::Deferrable. The object's callbacks will be executed
	# on the reactor main thread when the file has been completely scheduled for
	# transmission to the remote peer. Its errbacks will be called in case of an error
	# (such as file-not-found). #stream_file_data employs various strategems to achieve
	# the fastest possible performance, balanced against minimum consumption of memory.
	#
	# You can control the behavior of #stream_file_data with the optional arguments parameter.
	# Currently-supported arguments are:
	# :http_chunks, a boolean flag which defaults false. If true, this flag streams the
	# file data in a format compatible with the HTTP chunked-transfer encoding.
	#
	# Warning: this feature has an implicit dependency on an outboard extension,
	# evma_fastfilereader. You must install this extension in order to use #stream_file_data
	# with files larger than a certain size (currently 8192 bytes).
	#
	def stream_file_data filename, args={}
		EventMachine::FileStreamer.new( self, filename, args )
	end


	# TODO, document this
	#
	#
	class EventMachine::PeriodicTimer
		def initialize *args, &block
			@interval = args.shift
			@code = args.shift || block
			schedule
		end
		def schedule
			EventMachine::add_timer @interval, proc {self.fire}
		end
		def fire
			@code.call
			schedule unless @cancelled
		end
		def cancel
			@cancelled = true
		end
	end

	# TODO, document this
	#
	#
	class EventMachine::Timer
		def initialize *args, &block
			@signature = EventMachine::add_timer(*args, &block)
		end
		def cancel
			EventMachine.send :cancel_timer, @signature
		end
	end




end

module Protocols
	# In this module, we define standard protocol implementations.
	# They get included from separate source files.
end

end # module EventMachine



# Save everyone some typing.
EM = EventMachine
EM::P = EventMachine::Protocols


# At the bottom of this module, we load up protocol handlers that depend on some
# of the classes defined here. Eventually we should refactor this out so it's
# laid out in a more logical way.
#

require 'protocols/tcptest'
require 'protocols/httpclient'
require 'protocols/line_and_text'
require 'protocols/header_and_content'
require 'protocols/linetext2'
require 'protocols/httpcli2'
require 'protocols/stomp'
require 'protocols/smtpclient'
require 'protocols/smtpserver'
require 'protocols/saslauth'

require 'em/processes'


