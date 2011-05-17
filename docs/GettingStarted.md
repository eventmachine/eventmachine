# Getting started with Ruby EventMachine #


## About this guide ##

This guide is a quick tutorial that helps you to get started with EventMachine for writing event-driven
servers, clients and using it as a lightweight concurrency library.
It should take about 20 minutes to read and study the provided code examples. This guide covers

 * Installing EventMachine via [Rubygems](http://rubygems.org) and [Bundler](http://gembundler.com).
 * Building an Echo server, "Hello, world"-like code example of network servers.
 * Building a simple chat, both server and client parts of it.
 * Building a very small asynchronous Websockets client.


h2. Covered versions

This guide covers EventMachine v0.12.10 and 1.0 (including betas).


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

Lets begin with a classic "Hello, world" example. First, here's the code:

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
