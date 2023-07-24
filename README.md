# About EventMachine  [![Build Status](https://travis-ci.org/eventmachine/eventmachine.svg?branch=master)](https://travis-ci.org/eventmachine/eventmachine) [![Code Climate Maintainability](https://api.codeclimate.com/v1/badges/e9b0603462905d5b9118/maintainability)](https://codeclimate.com/github/eventmachine/eventmachine/maintainability)


## What is EventMachine ##

EventMachine is an event-driven I/O and lightweight concurrency library for Ruby.
It provides event-driven I/O using the [Reactor pattern](http://en.wikipedia.org/wiki/Reactor_pattern),
much like [JBoss Netty](http://www.jboss.org/netty), [Apache MINA](http://mina.apache.org/),
Python's [Twisted](http://twistedmatrix.com), [Node.js](http://nodejs.org), libevent and libev.

EventMachine is designed to simultaneously meet two key needs:

 * Extremely high scalability, performance and stability for the most demanding production environments.
 * An API that eliminates the complexities of high-performance threaded network programming,
   allowing engineers to concentrate on their application logic.

This unique combination makes EventMachine a premier choice for designers of critical networked
applications, including Web servers and proxies, email and IM production systems, authentication/authorization
processors, and many more.

EventMachine has been around since the early 2000s and is a mature and battle-tested library.


## What EventMachine is good for? ##

 * Scalable event-driven servers. Examples: [Thin](https://github.com/macournoyer/thin/) or [Goliath](https://github.com/postrank-labs/goliath/).
 * Scalable asynchronous clients for various protocols, RESTful APIs and so on. Examples: [em-http-request](https://github.com/igrigorik/em-http-request) or [amqp gem](https://github.com/ruby-amqp/amqp).
 * Efficient network proxies with custom logic. Examples: [Proxymachine](https://github.com/mojombo/proxymachine/).
 * File and network monitoring tools. Examples: [eventmachine-tail](https://github.com/jordansissel/eventmachine-tail) and [logstash](https://github.com/logstash/logstash).



## What platforms are supported by EventMachine? ##

EventMachine supports Ruby 2.0.0 and later (see tested versions at 
[.github/workflows/workflow.yml](.github/workflows/workflow.yml)). It runs on JRuby and **works well on Windows** 
as well as many operating systems from the Unix family (Linux, Mac OS X, BSD flavors).



## Prerequisite for the gem ##

To be installed, eventmachine requires a C/C++ compiler, Ruby development headers, and (optional, but typically desired) OpenSSL library and headers.

Each system/OS will provide this it's own way. Some examples follow below.
In any case, `libssl-dev` or its equivalent are optional.

### Debian/Ubuntu ###

You will need those:

    apt -qq update && apt -qqy install build-essential ruby-dev libssl-dev

Note that `libssl-dev` is optional as said previously. We tested those instructions on debian:bullseye, ubuntu:focal and ubuntu:jammy.

### Alpine (3) ###

You will need those instructions:

    apk add --no-cache build-base ruby-dev openssl-dev

### macos (Monterey 12.4) ###

It depends on the package manager you have installed (brew or port), but typically, the package manager will need the build tools so installing them will make this first step done.

Then install ruby with it, brew will keep the header and place them correctly. Finally, add if you need SSL. This should look like this with `brew`:

    brew install ruby@3 openssl@1.1

Instead of ruby, you can install rbenv and ruby-build, then install a global version of ruby will do to in place of installing ruby@3 on your system (you will be able to choose the ruby version depending on your project, headers will be present).

    brew install rbenv ruby-build openssl@1.1
    rbenv install 3.1.2
    rbenv global 3.1.2

## Install the gem ##

Install it with [RubyGems](https://rubygems.org/)

    gem install eventmachine

or add this to your Gemfile if you use [Bundler](http://gembundler.com/):

    gem 'eventmachine'



## Getting started ##

For an introduction to EventMachine, check out:

 * [blog post about EventMachine by Ilya Grigorik](http://www.igvita.com/2008/05/27/ruby-eventmachine-the-speed-demon/).
 * [EventMachine Introductions by Dan Sinclair](http://everburning.com/news/eventmachine-introductions.html).


### Server example: Echo server ###

Here's a fully-functional echo server written with EventMachine:

```ruby
 require 'eventmachine'

 module EchoServer
   def post_init
     puts "-- someone connected to the echo server!"
   end

   def receive_data data
     send_data ">>>you sent: #{data}"
     close_connection if data =~ /quit/i
   end

   def unbind
     puts "-- someone disconnected from the echo server!"
   end
end

# Note that this will block current thread.
EventMachine.run {
  EventMachine.start_server "127.0.0.1", 8081, EchoServer
}
```


## EventMachine documentation ##

Currently we only have [reference documentation](http://rubydoc.info/github/eventmachine/eventmachine/frames) and a [wiki](https://github.com/eventmachine/eventmachine/wiki).


## Community and where to get help ##

 * Join the [mailing list](http://groups.google.com/group/eventmachine) (Google Group)
 * Join IRC channel #eventmachine on irc.freenode.net


## License and copyright ##

EventMachine is copyrighted free software made available under the terms
of either the GPL or Ruby's License.

Copyright: (C) 2006-07 by Francis Cianfrocca. All Rights Reserved.


## Alternatives ##

If you are unhappy with EventMachine and want to use Ruby, check out [Celluloid](https://github.com/celluloid/celluloid).
