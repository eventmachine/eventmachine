# About EventMachine-LE #

EventMachine-LE (Live Edition) is a fork of [EventMachine](http://github.com/eventmachine/eventmachine).


## Purpose of this fork ##

This fork incorporates interesting pull requests that are not included in the official EventMachine repository, probably because developers prefer to keep the stability with already existing EventMachine deployments (most of them IPv4 HTTP servers which don't need good UDP or IPv6 support).

New proposals will also directly come to EventMachine-LE and will be included once they are tested.

This fork is just intended for Unix/Linux and BSD environtments. Java reactor and pure Ruby reactor are removed in this fork, and Windows/Cygwin support won't be tested.


## Features and changes ##

The list of additions and improvements will grow over time. Currently the following features/fixes have been applied in EventMachine-LE:

* Full IPv6 support for TCP and UDP, in both server and client mode ([cabo]([https://github.com/eventmachine/eventmachine/pull/297)).
* Added robustness to datagram sockets, which now can optionally not to get destroyed on the first error by setting `EM::Connection#send_error_handling=mode` ([cabo]([https://github.com/eventmachine/eventmachine/pull/297)).
* `EM::attach_server` added ([ramonmaruko](https://github.com/eventmachine/eventmachine/pull/271)).
* `EM::RestartableTimer` added ([adzap](https://github.com/eventmachine/eventmachine/pull/114)).
* `EM::get_max_timers` and `EM::set_max_timers` are removed (they still exist but do nothing). This solves the annoying "RuntimeError: max timers exceeded" exception.
* Many code cleanups.


## Installation ##

Install the Ruby Gem:
<pre>
gem install eventmachine-le
</pre>


## Usage ##

In order to use this fork in your project, make sure you load it as follows:
<pre>
# First load EventMachine-LE.
require "eventmachine-le"
# Later load any other Ruby Gem depending on EventMachine so they will use EventMachine-LE.
require "em-udns"
</pre>

By doing this, you will avoid conflicts with the official EventMachine Gem (if it's also installed).


## Authors ##

This fork is mantained by [Carsten Bormann](https://github.com/cabo) and [Iñaki Baz Castillo](https://github.com/ibc).