# @title Getting Started with Ruby EventMachine
# @markup markdown
# @author Michael S. Klishin, Dan Sinclair

# Getting started with Ruby EventMachine #


## About this guide ##

This guide is a quick tutorial that helps you to get started with EventMachine for writing event-driven
servers, clients and using it as a lightweight concurrency library.
It should take about 20 minutes to read and study the provided code examples. This guide covers

 * Installing EventMachine via [Rubygems](http://rubygems.org) and [Bundler](http://gembundler.com).
 * Building an Echo server, the "Hello, world"-like code example of network servers.
 * Building a simple chat, both server and client.
 * Building a very small asynchronous Websockets client.


## Covered versions ##

This guide covers EventMachine v0.12.10 and 1.0 (including betas).


## Level ##

This guide assumes you are comfortable (but not necessary a guru) with the command line. On Microsoft Windows™,
we recommend you to use [JRuby](http://jruby.org) when running these examples.


## Installing EventMachine ##

### Make sure you have Ruby installed ###

This guide assumes you have one of the supported Ruby implementations installed:

 * Ruby 1.8.7
 * Ruby 1.9.2
 * [JRuby](http://jruby.org) (we recommend 1.6)
 * [Rubinius](http://rubini.us) 1.2 or higher
 * [Ruby Enterprise Edition](http://www.rubyenterpriseedition.com)

EventMachine works on Microsoft Windows™.


### With Rubygems ###

To install the EventMachine gem do

    gem install eventmachine


### With Bundler ###

    gem "eventmachine"


### Verifying your installation ###

Lets verify your installation with this quick IRB session:

    irb -rubygems

    ruby-1.9.2-p180 :001 > require "eventmachine"
     => true
    ruby-1.9.2-p180 :002 > EventMachine::VERSION
     => "1.0.0.beta.3"


## An Echo Server Example ##

Lets begin with the classic "Hello, world"-like example, an echo server. The echo server responds clients with the
same data that was provided. First, here's the code:

{include:file:examples/guides/getting\_started/01\_eventmachine\_echo_server.rb}


When run, the server binds to port 10000. We can connect using Telnet and verify it's working:

    telnet localhost 10000

On my machine the output looks like:

    ~ telnet localhost 10000
    Trying 127.0.0.1...
    Connected to localhost.
    Escape character is '^]'.

Let's send something to our server. Type in "Hello, EventMachine" and hit Enter. The server will respond with
the same string:

    ~ telnet localhost 10000
    Trying 127.0.0.1...
    Connected to localhost.
    Escape character is '^]'.
    Hello, EventMachine
    # (here we hit Enter)
    Hello, EventMachine
    # (this ^^^ is our echo server reply)

It works! Congratulations, you now can tell your Node.js-loving friends that you "have done some event-driven programming, too".
Oh, and to stop Telnet, hit Control + Shift + ] and then Control + C.

Lets walk this example line by line and see what's going on. These lines

    require 'rubygems' # or use Bundler.setup
    require 'eventmachine'

probably look familiar: you use [RubyGems](http://rubygems.org) (or [Bundler](http://gembundler.com/)) for dependencies and then require EventMachine gem. Boring.

Next:

    class EchoServer < EventMachine::Connection
      def receive_data(data)
        send_data(data)
      end
    end

Is the implementation of our echo server. We define a class that inherits from {EventMachine::Connection}
and a handler (aka callback) for one event: when we receive data from a client.

EventMachine handles the connection setup, receiving data and passing it to our handler, {EventMachine::Connection#receive_data}.

Then we implement our protocol logic, which in the case of Echo is pretty trivial: we send back whatever we receive.
To do so, we're using {EventMachine::Connection#send_data}.

Lets modify the example to recognize `exit` command:

{include:file:examples/guides/getting\_started/02\_eventmachine\_echo_server\_that\_recognizes\_exit\_command.rb}

Our `receive\_data` changed slightly and now looks like this:

    def receive_data(data)
      if data.strip =~ /exit$/i
        EventMachine.stop_event_loop
      else
        send_data(data)
      end
    end

Because incoming data has trailing newline character, we strip it off before matching it against a simple regular
expression. If the data ends in `exit`, we stop EventMachine event loop with {EventMachine.stop_event_loop}. This unblocks
main thread and it finishes execution, and our little program exits as the result.

To summarize this first example:

 * Subclass {EventMachine::Connection} and override {EventMachine::Connection#send_data} to handle incoming data.
 * Use {EventMachine.run} to start EventMachine event loop and then bind echo server with {EventMachine.start_server}.
 * To stop the event loop, use {EventMachine.stop_event_loop} (aliased as {EventMachine.stop})

Lets move on to a slightly more sophisticated example that will introduce several more features and methods
EventMachine has to offer.



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
