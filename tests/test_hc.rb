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

# This doesn't completely work under Ruby 1.9.
# Part of it is thread race conditions. I added some sleeps to make these
# tests work. Native threads do strange things when you do I/O on them.
#
# And it's even worse in Java, where I/O on native threads doesn't seem
# to be reliable at all.
#


class TestHeaderAndContentProtocol < Test::Unit::TestCase

	TestHost = "127.0.0.1"
	TestPort = 8905


	#--------------------------------------------------------------------

	class SimpleTest < EventMachine::Protocols::HeaderAndContentProtocol
		attr_reader :first_header, :my_headers, :request

		def receive_first_header_line hdr
			@first_header ||= []
			@first_header << hdr
		end
		def receive_headers hdrs
			@my_headers ||= []
			@my_headers << hdrs
		end
		def receive_request hdrs, content
			@request ||= []
			@request << [hdrs, content]
		end
	end


	def test_no_content
		Thread.abort_on_exception = true
		the_connection = nil
		EventMachine.run {
			EventMachine.start_server( TestHost, TestPort, SimpleTest ) do |conn|
				the_connection = conn
			end
			EventMachine.add_timer(4) {raise "test timed out"}

			pr = proc {
				t = TCPSocket.new TestHost, TestPort
				t.write [ "aaa\n", "bbb\r\n", "ccc\n", "\n" ].join
				t.close
			}

			if RUBY_PLATFORM =~ /java/i
				pr.call
				EM.add_timer(0.5) {EM.stop}
			else
				EventMachine.defer proc {
					pr.call
					if RUBY_VERSION =~ /\A1\.9\./
						sleep 0.1
						STDERR.puts "Introducing extraneous sleep for Ruby 1.9"
					end
				}, proc {
					EventMachine.stop
				}
			end
		}
		assert_equal( ["aaa"], the_connection.first_header )
		assert_equal( [%w(aaa bbb ccc)], the_connection.my_headers )
		assert_equal( [[%w(aaa bbb ccc), ""]], the_connection.request )
	end




	def test_content
		Thread.abort_on_exception = true
		the_connection = nil
		content = "A" * 50
		headers = ["aaa", "bbb", "Content-length: #{content.length}", "ccc"]
		EventMachine.run {
			EventMachine.start_server( TestHost, TestPort, SimpleTest ) do |conn|
				the_connection = conn
			end
			EventMachine.add_timer(4) {raise "test timed out"}

			pr = proc {
				t = TCPSocket.new TestHost, TestPort
				headers.each {|h| t.write "#{h}\r\n" }
				t.write "\n"
				t.write content
				t.close
			}

			if RUBY_PLATFORM =~ /java/i
				# I/O on threads seems completely unreliable in Java.
				pr.call
				EM.add_timer(0.5) {EM.stop}
			else
				EventMachine.defer proc {
					pr.call
					if RUBY_VERSION =~ /\A1\.9\./
						sleep 0.1
						STDERR.puts "Introducing extraneous sleep for Ruby 1.9"
					end
				}, proc {
					EM.stop
				}
			end
		}
		assert_equal( ["aaa"], the_connection.first_header )
		assert_equal( [headers], the_connection.my_headers )
		assert_equal( [[headers, content]], the_connection.request )
	end



	def test_several_requests
		Thread.abort_on_exception = true
		the_connection = nil
		content = "A" * 50
		headers = ["aaa", "bbb", "Content-length: #{content.length}", "ccc"]
		EventMachine.run {
			EventMachine.start_server( TestHost, TestPort, SimpleTest ) do |conn|
				the_connection = conn
			end
			EventMachine.add_timer(4) {raise "test timed out"}

			pr = proc {
				t = TCPSocket.new TestHost, TestPort
				5.times {
					headers.each {|h| t.write "#{h}\r\n" }
					t.write "\n"
					t.write content
				}
				t.close
			}

			if RUBY_PLATFORM =~ /java/i
				pr.call
				EM.add_timer(1) {EM.stop}
			else
				EventMachine.defer proc {
					pr.call
					if RUBY_VERSION =~ /\A1\.9\./
						sleep 0.1
						STDERR.puts "Introducing extraneous sleep for Ruby 1.9"
					end
				}, proc {
					EventMachine.stop
				}
			end
		}
		assert_equal( ["aaa"] * 5, the_connection.first_header )
		assert_equal( [headers] * 5, the_connection.my_headers )
		assert_equal( [[headers, content]] * 5, the_connection.request )
	end


    def x_test_multiple_content_length_headers
	# This is supposed to throw a RuntimeError but it throws a C++ exception instead.
	Thread.abort_on_exception = true
	the_connection = nil
	content = "A" * 50
	headers = ["aaa", "bbb", ["Content-length: #{content.length}"]*2, "ccc"].flatten
	EventMachine.run {
	    EventMachine.start_server( TestHost, TestPort, SimpleTest ) do |conn|
		the_connection = conn
	    end
	    EventMachine.add_timer(4) {raise "test timed out"}
	    EventMachine.defer proc {
		t = TCPSocket.new TestHost, TestPort
		headers.each {|h| t.write "#{h}\r\n" }
		t.write "\n"
		t.write content
		t.close
	    }, proc {
		EventMachine.stop
	    }
	}
    end

	def test_interpret_headers
		Thread.abort_on_exception = true
		the_connection = nil
		content = "A" * 50
		headers = [
			"GET / HTTP/1.0",
			"Accept: aaa",
			"User-Agent: bbb",
			"Host:	    ccc",
			"x-tempest-header:ddd"
		]

		EventMachine.run {
			EventMachine.start_server( TestHost, TestPort, SimpleTest ) do |conn|
				the_connection = conn
			end
			EventMachine.add_timer(4) {raise "test timed out"}

			pr = proc {
				t = TCPSocket.new TestHost, TestPort
				headers.each {|h| t.write "#{h}\r\n" }
				t.write "\n"
				t.write content
				t.close
			}

			if RUBY_PLATFORM =~ /java/i
				pr.call
				EM.add_timer(0.5) {EM.stop}
			else
				EventMachine.defer proc {
					pr.call
					if RUBY_VERSION =~ /\A1\.9\./
						sleep 0.1
						STDERR.puts "Introducing extraneous sleep for Ruby 1.9"
					end
				}, proc {
					EventMachine.stop
				}
			end
		}

		hsh = the_connection.headers_2_hash( the_connection.my_headers.shift )
		assert_equal(
			{
				:accept => "aaa",
				:user_agent => "bbb",
				:host => "ccc",
				:x_tempest_header => "ddd"
			},
			hsh
		)
	end


end


