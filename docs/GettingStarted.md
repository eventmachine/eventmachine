# @title Getting Started with Ruby EventMachine
# @markup markdown
# @author Michael S. Klishin, Dan Sinclair

# Getting started with Ruby EventMachine #


## About this guide ##

This guide is a quick tutorial that helps you to get started with EventMachine for writing event-driven
servers, clients and using it as a lightweight concurrency library.
It should take about 20 minutes to read and study the provided code examples. This guide covers

 * Installing EventMachine via [Rubygems](http://rubygems.org) and [Bundler](http://gembundler.com).
 * Building an Echo server, "Hello, world"-like code example of network servers.
 * Building a simple chat, both server and client parts of it.
 * Building a very small asynchronous Websockets client.


## Covered versions ##

This guide covers EventMachine v0.12.10 and 1.0 (including betas).


## Level ##

This guide assumes you are comfortable (but not necessary a guru) with the command line. On Microsoft Windows™,
we recommend you to use [JRuby](http://jruby.org) when running these examples.


## Installing EventMachine ##

### Make sure you have Ruby installed ###

This guides assumes you have one of the supported Ruby implementations installed:

 * Ruby 1.8.7
 * Ruby 1.9.2
 * [JRuby](http://jruby.org) (we recommend 1.6)
 * [Rubinius](http://rubini.us) 1.2 or higher
 * [Ruby Enterprise Edition](http://www.rubyenterpriseedition.com)

EventMachine works on Microsoft Windows™.


### With Rubygems ###

To install EventMachine gem do

    gem install eventmachine


### With Bundler ###

    gem "eventmachine"


### Verifying your installation ###

Lets verify your installation with this quick irb session:

    irb -rubygems

    ruby-1.9.2-p180 :001 > require "eventmachine"
     => true
    ruby-1.9.2-p180 :002 > EventMachine::VERSION
     => "1.0.0.beta.3"


## An echo server example ##

Lets begin with a classic "Hello, world"-like example, an echo server. Echo server sends back whatever it receives
from clients and does nothing else. First, here's the code:

{include:file:examples/guides/getting\_started/01\_eventmachine\_echo_server.rb}


When this code example is run, server binds to port 10000. Lets connect there using Telnet and see if it works:
run this example in one shell and in another shell run

    telnet localhost 10000

to connect to our echo server. On my machine, it looks like this:

    ~ telnet localhost 10000
    Trying ::1...
    telnet: connect to address ::1: Connection refused
    Trying fe80::1...
    telnet: connect to address fe80::1: Connection refused
    Trying 127.0.0.1...
    Connected to localhost.
    Escape character is '^]'.

Lets send something to our server. Type in "Hello, EventMachine" and hit Enter. Server will reply with exactly what we've
sent it:

    ~ telnet localhost 10000
    Trying ::1...
    telnet: connect to address ::1: Connection refused
    Trying fe80::1...
    telnet: connect to address fe80::1: Connection refused
    Trying 127.0.0.1...
    Connected to localhost.
    Escape character is '^]'.
    Hello, EventMachine
    # (here we hit Enter)
    Hello, EventMachine
    # (this ^^^ is our echo server reply)

It works! Congratulations, you now can tell your Node.js-loving friends that you "have done some event-driven programming, too".
Oh, and to stop Telnet, hit Control + Shift + ] and then Control + C.

Lets walk this example line by line and learn what is going on there. These lines

    require 'rubygems' # or use Bundler.setup
    require 'eventmachine'

probably look familiar: you use [RubyGems](http://rubygems.org) (or [Bundler](http://gembundler.com/)) for dependencies and then require EventMachine gem. Boring.
This piece of code

    class EchoServer < EventMachine::Connection
      def receive_data(data)
        send_data(data)
      end
    end

is the whole implementation of our echo server. We define a class that inherits from {EventMachine::Connection}
and defines a handler (aka callback) for one event: when we receive some data from a client.

EventMachine handles connection setup for us, fetches data for us and passes it to the handler we define, {EventMachine::Connection#receive_data}.
Then we implement our protocol logic, which in case of Echo protocol is pretty trivial: we send back whatever we receive.
To do so, we use {EventMachine::Connection#send_data} method.





TBD


## Wrapping up ##

This tutorial ends here. Congratulations! You have learned quite a bit about EventMachine.


## What to read next ##

The documentation is organized as a {file:docs/DocumentationGuidesIndex.md number of guides}, covering all kinds of
topics. TBD


## Tell us what you think! ##

Please take a moment and tell us what you think about this guide on the [EventMachine mailing list](http://bit.ly/jW3cR3)
or in the #eventmachine channel on irc.freenode.net: what was unclear? What wasn't covered?
Maybe you don't like the guide style or the grammar and spelling are incorrect? Reader feedback is
key to making documentation better.
